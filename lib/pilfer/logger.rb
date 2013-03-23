module Pilfer
  class Logger
    attr_reader :io, :app_root

    def initialize(io, options = {})
      @io = io
      if (app_root = options[:app_root])
        app_root << '/' unless app_root[-1] == '/'
        @app_root = %r{^#{Regexp.escape(app_root)}}
      end
    end

    def write(profile, profile_start)
      formatted = RbLineProfFormat.format_profile(profile, profile_start)
      strip_app_root_from_files formatted['profile']['files'] if app_root
      io.puts JSON.generate(formatted)
    end

    def strip_app_root_from_files(files)
      files.keys.each do |key|
        files[key.gsub(app_root, '')] = files.delete(key)
      end
    end
  end

  # Formatting a profile as JSON may eventually be provided by rblineprof.
  class RbLineProfFormat
    def self.format_profile(profile, profile_start)
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

        total, child, exclusive,
          total_cpu, child_cpu, exclusive_cpu = lines[0]

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
