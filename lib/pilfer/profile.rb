module Pilfer
  class Profile
    include Enumerable
    attr_accessor :data, :start

    def initialize(data, start)
      @data  = data
      @start = start
    end

    def each(&block)
      files.to_a.sort_by(&:first).each(&block)
    end

    def files
      data.inject({}) do |files, (file, lines)|
        profile_lines = {}
        lines[1..-1].each_with_index do |data, number|
          next unless data.any? {|datum| datum > 0 }
          wall_time, cpu_time, calls = data
          profile_lines[number] = { 'wall_time' => wall_time,
                                    'cpu_time'  => cpu_time,
                                    'calls'     => calls }
        end

        total_wall, child_wall, exclusive_wall,
          total_cpu, child_cpu, exclusive_cpu = lines[0]

        wall = total_wall
        cpu  = total_cpu

        files[file] = { 'wall_time' => wall,
                        'cpu_time'  => cpu,
                        'lines'     => profile_lines }
        files
      end
    end
  end
end
