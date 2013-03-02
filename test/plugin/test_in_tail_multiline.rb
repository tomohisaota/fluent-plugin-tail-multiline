require 'helper'

require 'tempfile'

class TailMultilineInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
  ]
  # CONFIG = %[
  #   path #{TMP_DIR}/out_file_test
  #   compress gz
  #   utc
  # ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::TailMultilineInput).configure(conf)
  end
  
  def test_emit
    tmpFile = Tempfile.new("in_tail_multiline-")
    puts tmpFile.path
    File.open(tmpFile.path, "w") {|f|
      f.puts "test1"
      f.puts "test2"
    }

    d = create_driver %[
      path #{tmpFile.path}
      tag test
      format /(?<message>.*)/
    ]

    d.run do
      sleep 1

      File.open(tmpFile.path, "a") {|f|
        f.puts "test3"
        f.puts "test4"
      }
      sleep 1
    end

    emits = d.emits
    assert_equal(true, emits.length > 0)
    assert_equal({"message"=>"test3"}, emits[0][2])
    assert_equal({"message"=>"test4"}, emits[1][2])   
  end
end