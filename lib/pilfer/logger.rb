require 'pilfer/profile'

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

    def write(profile_data, profile_start)
      profile = Pilfer::Profile.new(profile_data, profile_start)
      File.open(path, 'a') do |file|
        print_report_banner file, profile_start
        profile.each do |path, data|
          print_file_banner file, path, data
          print_file_source_with_profile file, path, data
        end
      end
    end

    private

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

    def print_file_source_with_profile(file, path, data)
      return unless File.exists?(path)
      File.readlines(path).each_with_index do |line_source, index|
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

    def strip_app_root(path)
      return path unless app_root
      path.gsub(app_root, '')
    end
  end
end
