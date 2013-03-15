require 'rblineprof'

module Pilfer
  class Middleware
    VERSION = '0.0.1'

    attr_reader :app, :app_root, :match

    def initialize(app, options = {})
      @app      = app
      @app_root = File.expand_path(options.fetch(:app_root, '.'))
      @match    = options[:match] || default_match
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

      payload = RbLineProfFormat.profile_to_json(profile, profile_start)
      payload['file_contents'] = file_contents_for_profile(profile)
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
      post_profile_payload(payload)

      # TODO: Post profile in a thread.
      # Thread.new(payload) do |payload|
      #   begin
      #     post_profile_payload(payload)
      #   rescue Exception => ex
      #     log_error(ex)
      #   end
      # end
    end

    def post_profile_payload(payload)
      uri   = URI.parse(ENV['PILFER_URL'] || 'http://google.com:1234')
      token = ENV['PILFER_TOKEN']

      request = Net::HTTP::Post.new('/api/v1/profiles')
      request.content_type = 'application/json'
      request['Authorization'] = %{Token token="#{token}"}
      request.body = JSON.generate(payload)

      http = Net::HTTP.new(uri.host, uri.port)

      # TODO: Use SSL
      # http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      # http.use_ssl = true
      # store = OpenSSL::X509::Store.new
      # store.set_default_paths
      # http.cert_store = store

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
