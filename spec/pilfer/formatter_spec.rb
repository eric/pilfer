require 'json'
require 'pilfer/formatter'

describe Pilfer::Formatter do
  let(:spec_root) { File.expand_path('..', File.dirname(__FILE__)) }
  let(:profile) {
    profile_file    = File.join(spec_root, 'files', 'profile.json')
    profile_content = File.read(profile_file).gsub('SPEC_ROOT', spec_root)
    JSON.parse(profile_content)
  }
  let(:start) { Time.at(42) }

  describe '.json' do
    it 'formats profile as json' do
      expected = {
        "profile" => {
          "version"   => "0.2.5",
          "timestamp" => 42,
          "files"     => {
            "#{spec_root}/files/test.rb" => {
              "wall_time" => 113692,
              "cpu_time"  => 5313,
              "lines"     => {
                11 => { "wall_time" => 5062,   "cpu_time" => 4890, "calls" => 3 },
                12 => { "wall_time" => 23,     "cpu_time" => 14,   "calls" => 4 },
                13 => { "wall_time" => 108607, "cpu_time" => 409,  "calls" => 1 },
                14 => { "wall_time" => 108404, "cpu_time" => 310,  "calls" => 10 }
              }
            },
            "#{spec_root}/files/hello.rb" => {
              "wall_time" => 31,
              "cpu_time"  => 18,
              "lines"     => {
                0 => { "wall_time" => 31, "cpu_time" => 18, "calls" => 2} }
            }
          }
        }
      }
      Pilfer::Formatter.json(profile, start).should eq(expected)
    end
  end
end
