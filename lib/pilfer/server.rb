require 'json'
require 'net/http'
require 'pilfer/profile'
require 'uri'

module Pilfer
  class Server
    attr_accessor :uri, :token

    def initialize(uri, token)
      @uri   = URI.parse(uri)
      @token = token
    end

    def write(profile_data, profile_start, description)
      details = { 'hostname'     => Socket.gethostname,
                  'pid'          => Process.pid,
                  'description'  => description,
                  'file_sources' => file_sources_for_profile(profile_data) }

      payload = RbLineProfFormat.
                  profile_to_json(profile_data, profile_start).
                  merge(details)

      Thread.new(payload) do
        submit_profile payload
      end
    end

    private

    def submit_profile(payload)
      request = Net::HTTP::Post.new('/api/v1/profiles')
      request.content_type = 'application/json'
      request['Authorization'] = %{Token token="#{token}"}
      request.body = JSON.generate(payload)

      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
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
    rescue Exception => ex
      $stdout.puts ex.message, ex.backtrace
    end

    def file_sources_for_profile(profile_data)
      profile_data.each_with_object({}) {|(file, _), sources|
        sources[file] = File.exists?(file) ? File.read(file) : nil
      }
    end
  end
end

# Formatting a profile as JSON may eventually be provided by rblineprof.
class RbLineProfFormat
  def self.profile_to_json(profile_data, profile_start)
    files = profile_data.each_with_object({}) do |(file, lines), files|
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
        'timestamp' => profile_start.to_i,
        'files'     => files
      }
    }
  end
end
