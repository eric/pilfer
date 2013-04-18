require 'helper'
require 'json'
require 'pilfer/profile'

describe Pilfer::Profile do
  let(:spec_root) { File.expand_path('..', File.dirname(__FILE__)) }
  let(:data)      {
    profile_file    = File.join(spec_root, 'files', 'profile.json')
    profile_content = File.read(profile_file).gsub('SPEC_ROOT', spec_root)
    JSON.parse(profile_content)
  }
  let(:start) { Time.at(42) }
  subject { Pilfer::Profile.new(data, start) }

  it 'should be an Enumerable' do
    subject.should be_kind_of(Enumerable)
  end

  describe '#start' do
    it 'returns the given start time' do
      subject.start.should eq(start)
    end
  end

  describe '#each' do
    it 'yields each file and data' do
      actual  = {}
      subject.each do |file, data|
        actual[file] = data
      end
      expected = {
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
      actual.should eq(expected)
    end
  end
end
