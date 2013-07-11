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
  
  def test_emit_no_additional_option
    tmpFile = Tempfile.new("in_tail_multiline-")
    begin
      d = create_driver %[
        path #{tmpFile.path}
        tag test
        format /^[s|f] (?<message>.*)/
      ]
      d.run do
        File.open(tmpFile.path, "w") {|f|
          f.puts "f test1"
          f.puts "s test2"
          f.puts "f test3"
          f.puts "f test4"
          f.puts "s test5"
          f.puts "s test6"
          f.puts "f test7"
          f.puts "s test8"
        }
        sleep 1
      end

      emits = d.emits
      assert_equal(true, emits.length > 0)
      assert_equal({"message"=>"test1"}, emits[0][2])
      assert_equal({"message"=>"test2"}, emits[1][2])
      assert_equal({"message"=>"test3"}, emits[2][2])
      assert_equal({"message"=>"test4"}, emits[3][2])
      assert_equal({"message"=>"test5"}, emits[4][2])
      assert_equal({"message"=>"test6"}, emits[5][2])
      assert_equal({"message"=>"test7"}, emits[6][2])
      assert_equal({"message"=>"test8"}, emits[7][2])
    ensure
      tmpFile.close(true)
    end
  end
  
  def test_emit_with_rawdata
    tmpFile = Tempfile.new("in_tail_multiline-")
    begin
      d = create_driver %[
        path #{tmpFile.path}
        tag test
        format /^[s|f] (?<message>.*)/
        rawdata_key rawdata
      ]
      d.run do
        File.open(tmpFile.path, "w") {|f|
          f.puts "f test1"
          f.puts "s test2"
          f.puts "f test3"
          f.puts "f test4"
          f.puts "s test5"
          f.puts "s test6"
          f.puts "f test7"
          f.puts "s test8"
        }
        sleep 1
      end

      emits = d.emits
      assert_equal(true, emits.length > 0)
      assert_equal({"message"=>"test1","rawdata"=>"f test1"}, emits[0][2])
      assert_equal({"message"=>"test2","rawdata"=>"s test2"}, emits[1][2])
      assert_equal({"message"=>"test3","rawdata"=>"f test3"}, emits[2][2])
      assert_equal({"message"=>"test4","rawdata"=>"f test4"}, emits[3][2])
      assert_equal({"message"=>"test5","rawdata"=>"s test5"}, emits[4][2])
      assert_equal({"message"=>"test6","rawdata"=>"s test6"}, emits[5][2])
      assert_equal({"message"=>"test7","rawdata"=>"f test7"}, emits[6][2])
      assert_equal({"message"=>"test8","rawdata"=>"s test8"}, emits[7][2])
    ensure
      tmpFile.close(true)
    end
  end
  def test_emit_with_format_firstline
    tmpFile = Tempfile.new("in_tail_multiline-")
    begin
      d = create_driver %[
        path #{tmpFile.path}
        tag test
        format /^[s|f] (?<message>.*)/
        format_firstline /^[s]/
      ]
      d.run do
        File.open(tmpFile.path, "w") {|f|
          f.puts "f test1"
          f.puts "s test2"
          f.puts "f test3"
          f.puts "f test4"
          f.puts "s test5"
          f.puts "s test6"
          f.puts "f test7"
          f.puts "s test8"
        }
        sleep 1
      end

      emits = d.emits
      assert_equal(true, emits.length > 0)
      n = -1
      assert_equal({"message"=>"test2\nf test3\nf test4"}, emits[0][2])
      assert_equal({"message"=>"test5"}, emits[1][2])
      assert_equal({"message"=>"test6\nf test7"}, emits[2][2])
      assert_equal({"message"=>"test8"}, emits[3][2])
    ensure
      tmpFile.close(true)
    end
  end
  
  def test_emit_with_format_firstline_with_rawdata
    tmpFile = Tempfile.new("in_tail_multiline-")
    begin
      d = create_driver %[
        path #{tmpFile.path}
        tag test
        format /^[s|f] (?<message>.*)/
        format_firstline /^[s]/
        rawdata_key rawdata
      ]
      d.run do
        File.open(tmpFile.path, "w") {|f|
          f.puts "f test1"
          f.puts "s test2"
          f.puts "f test3"
          f.puts "f test4"
          f.puts "s test5"
          f.puts "s test6"
          f.puts "f test7"
          f.puts "s test8"
        }
        sleep 1
      end

      emits = d.emits
      assert_equal(true, emits.length > 0)
      n = -1
      assert_equal({"message"=>"test2\nf test3\nf test4","rawdata"=>"s test2\nf test3\nf test4"}, emits[0][2])
      assert_equal({"message"=>"test5","rawdata"=>"s test5"}, emits[1][2])
      assert_equal({"message"=>"test6\nf test7","rawdata"=>"s test6\nf test7"}, emits[2][2])
      assert_equal({"message"=>"test8","rawdata"=>"s test8"}, emits[3][2])
    ensure
      tmpFile.close(true)
    end
  end
  
  def test_multilinelog
    tmpFile = Tempfile.new("in_tail_multiline-")
    begin
      d = create_driver %[
        path #{tmpFile.path}
        tag test
        format /^s (?<message1>[^\\n]+)(\\nf (?<message2>[^\\n]+))?(\\nf (?<message3>.*))?/
        format_firstline /^[s]/
        rawdata_key rawdata
      ]
      d.run do
        File.open(tmpFile.path, "w") {|f|
          f.puts "f test1"
          f.puts "s test2"
          f.puts "f test3"
          f.puts "f test4"
          f.puts "s test5"
          f.puts "s test6"
          f.puts "f test7"
          f.puts "s test8"
        }
        sleep 1
      end

      emits = d.emits
      assert_equal(true, emits.length > 0)
      n = -1
      assert_equal({"message1"=>"test2","message2"=>"test3","message3"=>"test4","rawdata"=>"s test2\nf test3\nf test4"}, emits[0][2])
      assert_equal({"message1"=>"test5","rawdata"=>"s test5"}, emits[1][2])
      assert_equal({"message1"=>"test6","message2"=>"test7","rawdata"=>"s test6\nf test7"}, emits[2][2])
      assert_equal({"message1"=>"test8","rawdata"=>"s test8"}, emits[3][2])
    ensure
      tmpFile.close(true)
    end
  end
  
  def test_multilinelog_with_serial_number_format
    tmpFile = Tempfile.new("in_tail_multiline-")
    begin
      d = create_driver %[
        path #{tmpFile.path}
        tag test
        format1 /^s (?<message1>[^\\n]+)\\n?/
        format2 /(f (?<message2>[^\\n]+)\\n?)?/
        format3 /(f (?<message3>.*))?/
        format_firstline /^[s]/
        rawdata_key rawdata
      ]
      d.run do
        File.open(tmpFile.path, "w") {|f|
          f.puts "f test1"
          f.puts "s test2"
          f.puts "f test3"
          f.puts "f test4"
          f.puts "s test5"
          f.puts "s test6"
          f.puts "f test7"
          f.puts "s test8"
        }
        sleep 1
      end

      emits = d.emits
      assert_equal(true, emits.length > 0)
      n = -1
      assert_equal({"message1"=>"test2","message2"=>"test3","message3"=>"test4","rawdata"=>"s test2\nf test3\nf test4"}, emits[0][2])
      assert_equal({"message1"=>"test5","rawdata"=>"s test5"}, emits[1][2])
      assert_equal({"message1"=>"test6","message2"=>"test7","rawdata"=>"s test6\nf test7"}, emits[2][2])
      assert_equal({"message1"=>"test8","rawdata"=>"s test8"}, emits[3][2])
    ensure
      tmpFile.close(true)
    end
  end

end
