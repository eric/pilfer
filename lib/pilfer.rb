require 'rblineprof'
require 'socket'

module Pilfer
  class Middleware
    VERSION = '0.0.1'

    attr_reader :app, :app_root, :match, :service_url, :service_token

    def initialize(app, options = {})
      enforce_required_options(options)
      @app           = app
      @app_root      = File.expand_path(options[:app_root] || '.')
      @match         = options[:match] || default_match
      @service_url   = URI.parse(options[:service_url])
      @service_token = options[:service_token]
    end

    def enforce_required_options(options)
      unless options.has_key?(:service_url)
        raise 'Pilfer::Middleware requires :service_url'
      end

      unless options.has_key?(:service_token)
        raise 'Pilfer::Middleware requires :service_token'
      end
    end

    def default_match
      %r{^#{app_root}/(app|config|lib|vendor/plugin)}
    end

    def call(env)
      profile_start = Time.now.utc
      response      = nil
      profile       = lineprof(match) do
        response = @app.call(env)
      end

      description = "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
      details = {'hostname'      => Socket.gethostname,
                 'pid'           => Process.pid,
                 'description'   => description,
                 'file_contents' => file_contents_for_profile(profile)}

      payload = RbLineProfFormat.
                  profile_to_json(profile, profile_start).
                  merge(details)

      # log_profile_payload payload
      submit_profile_payload payload

      response
    end

    def log_profile_payload(payload)
      require 'json'
      log = File.join(app_root, 'pilfer.log')
      File.open(log, 'a') do |log|
        log.puts JSON.pretty_generate(payload)
      end
    end

    def submit_profile_payload(payload)
      Thread.new(payload) do |payload|
        begin
          post_profile_payload(payload)
        rescue Exception => ex
          $stdout.puts ex.message, ex.backtrace
        end
      end
    end

    def post_profile_payload(payload)
      request = Net::HTTP::Post.new('/api/v1/profiles')
      request.content_type = 'application/json'
      request['Authorization'] = %{Token token="#{service_token}"}
      request.body = JSON.generate(payload)

      http = Net::HTTP.new(service_url.host, service_url.port)

      if service_url.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.use_ssl = true
        store = OpenSSL::X509::Store.new
        store.set_default_paths
        http.cert_store = store
      end

      case (response = http.start {|http| http.request(request) })
      when Net::HTTPSuccess, Net::HTTPRedirection
      else
        response.error!
      end
    end

    def file_contents_for_profile(profile)
      profile.each_with_object({}) {|(file, _), contents|
        contents[file] = File.exists?(file) ? File.read(file) : nil
      }
    end
  end

  # Formatting a profile as JSON may eventually be provided by rblineprof.
  class RbLineProfFormat
    def self.profile_to_json(profile, profile_start)
      files = profile.each_with_object({}) do |(file, lines), files|
        profile_lines = lines[1..-1].
                          each_with_index.
                          each_with_object({}) do |(data, number), lines|
          next unless data.any? {|datum| datum > 0 }
          wall_time, cpu_time, calls = data
          lines[number] = { 'wall_time' => wall_time,
                            'cpu_time'  => cpu_time,
                            'calls'     => calls }
        end

        total, child, exclusive, total_cpu, child_cpu, exclusive_cpu = lines[0]

        files[file] = { 'total'         => total,
                        'child'         => child,
                        'exclusive'     => exclusive,
                        'total_cpu'     => total_cpu,
                        'child_cpu'     => child_cpu,
                        'exclusive_cpu' => exclusive_cpu,
                        'lines'         => profile_lines }
      end

      {
        'profile' => {
          'version'   => '0.2.5',
          'timestamp' => profile_start.to_i,
          'files'     => files
        }
      }
    end
  end
end
