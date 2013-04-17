require 'logger'
require 'pilfer/profile'

module Pilfer
  class Logger
    attr_reader :app_root, :logger

    def initialize(path_or_io, options = {})
      @logger = ::Logger.new(path_or_io)
      if (app_root = options[:app_root])
        app_root += '/' unless app_root[-1] == '/'
        @app_root = %r{^#{Regexp.escape(app_root)}}
      end
    end

    def write(profile_data, profile_start)
      profile = Pilfer::Profile.new(profile_data, profile_start)
      print_report_banner profile_start
      profile.each do |path, data|
        print_file_banner path, data
        print_file_source_with_profile path, data
      end
    end

    private

    def print_report_banner(profile_start)
      logger.info "Profile start=#{profile_start.utc.to_s}"
    end

    def print_file_banner(path, data)
      wall = data['wall_time'] / 1000.0
      cpu  = data['cpu_time']  / 1000.0
      logger.info sprintf("%s wall_time=%.1fms cpu_time=%.1fms",
                          strip_app_root(path), wall, cpu)
    end

    def print_file_source_with_profile(path, data)
      return unless File.exists?(path)
      File.readlines(path).each_with_index do |line_source, index|
        line_source  = line_source.chomp
        line_profile = data['lines'][index]
        if line_profile && line_profile['calls'] > 0
          total = line_profile['wall_time']
          logger.info sprintf("% 8.1fms (% 5d) | %s",
                              total/1000.0,
                              line_profile['calls'],
                              line_source)
        else
          logger.info sprintf("                   | %s", line_source)
        end
      end
    end

    def strip_app_root(path)
      return path unless app_root
      path.gsub(app_root, '')
    end
  end
end
