require 'rblineprof'

module Pilfer
  class Middleware
    VERSION = '0.0.1'

    attr_reader :app, :app_root, :match

    def initialize(app, app_root, match = :default)
      @app      = app
      @app_root = File.expand_path(app_root)
      @match    = match == :default ? default_match : match
    end

    def default_match
      %r{^#{app_root}/(app|config|lib|vendor/plugin)}
    end

    def call(env)
      response = nil
      profile  = lineprof(match) do
        response = @app.call(env)
      end

      payload = RbLineProfFormat.profile_to_json(profile)
      payload['file_contents'] = file_contents_for_profile(profile)
      submit_profile payload

      response
    end

    def submit_profile(payload)
      require 'json'
      log = File.join(app_root, 'pilfer.log')
      File.open(log, 'a') do |log|
        log.puts JSON.pretty_generate(payload)
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
    def self.profile_to_json(profile)
      files = profile.each_with_object({}) do |(file, lines), files|
        total, child, exclusive, total_cpu, child_cpu, excl_cpu = lines[0]
        lines = lines[1..-1].
                  each_with_index.
                  each_with_object({}) do |(data, number), lines|
          next unless data.any? {|datum| datum > 0 }
          wall_time, cpu_time, calls = data
          lines[number] = { 'wall_time' => wall_time,
                            'cpu_time'  => cpu_time,
                            'calls'     => calls }
        end

        files[file] = { 'total'     => total,
                        'child'     => child,
                        'exclusive' => exclusive,
                        'lines'     => lines }
      end

      {
        'profile' => {
          'version'   => '0.2.5',
          'timestamp' => Time.now.utc.to_i,
          'files'     => files
        }
      }
    end
  end
end
