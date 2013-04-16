require 'pilfer/formatter'

module Pilfer
  class Logger
    attr_reader :io, :app_root

    def initialize(io, options = {})
      @io = io
      if (app_root = options[:app_root])
        app_root += '/' unless app_root[-1] == '/'
        @app_root = %r{^#{Regexp.escape(app_root)}}
      end
    end

    def write(profile, profile_start)
      formatted = Pilfer::Formatter.json(profile, profile_start)
      print_banner profile_start
      formatted['profile']['files'].each do |path, data|
        io.puts strip_app_root(path)
        file_source = File.read(path).split("\n")
        file_source.each_with_index do |line_source, index|
          line_profile = data['lines'][index]
          if line_profile && line_profile['calls'] > 0
            total = line_profile['wall_time']
            io.puts sprintf("% 8.1fms (% 5d) | %s", total/1000.0,
                                                    line_profile['calls'],
                                                    line_source)
          else
            io.puts sprintf("                   | %s", line_source)
          end
        end
        io.puts
      end
    end

    def strip_app_root(path)
      return path unless app_root
      path.gsub(app_root, '')
    end

    def print_banner(profile_start)
      io.puts '#' * 50
      io.puts "# #{profile_start.utc.to_s}"
      io.puts '#' * 50
      io.puts
    end
  end
end
