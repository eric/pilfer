require 'pilfer/formatter'

module Pilfer
  class Logger
    attr_reader :path, :app_root

    def initialize(path, options = {})
      @path = path
      if (app_root = options[:app_root])
        app_root += '/' unless app_root[-1] == '/'
        @app_root = %r{^#{Regexp.escape(app_root)}}
      end
    end

    def write(profile, profile_start)
      File.open(path, 'w') do |file|
        print_report_banner file, profile_start

        formatted = Pilfer::Formatter.json(profile, profile_start)
        formatted['profile']['files'].each do |path, data|
          print_file_banner file, path, data
          file_source = File.read(path).split("\n")
          file_source.each_with_index do |line_source, index|
            line_profile = data['lines'][index]
            if line_profile && line_profile['calls'] > 0
              total = line_profile['wall_time']
              file.puts sprintf("% 8.1fms (% 5d) | %s",
                                total/1000.0,
                                line_profile['calls'],
                                line_source)
            else
              file.puts sprintf("                   | %s", line_source)
            end
          end
          file.puts
        end
      end
    end

    def strip_app_root(path)
      return path unless app_root
      path.gsub(app_root, '')
    end

    def print_report_banner(file, profile_start)
      file.puts '#' * 50
      file.puts "# #{profile_start.utc.to_s}"
      file.puts '#' * 50
      file.puts
    end

    def print_file_banner(file, path, data)
      wall = data['wall_time'] / 1000.0
      cpu  = data['cpu_time']  / 1000.0
      file.puts sprintf("%s wall_time=%.1fms cpu_time=%.1fms",
                        strip_app_root(path), wall, cpu)
    end
  end
end
