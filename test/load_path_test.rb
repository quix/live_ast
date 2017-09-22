require_relative 'main'

class LoadPathTest < BaseTest
  include FileUtils

  def test_load_path
    $LOAD_PATH.unshift DATA_DIR
    begin
      check_load
      check_errors
      temp_file nil, "foo.rb" do
        Dir.chdir(DATA_DIR) do
          compare_load_errors("/foo.rb")
        end
      end
    ensure
      $LOAD_PATH.shift
    end
  end

  def test_chdir
    mkdir DATA_DIR, verbose: false
    Dir.chdir(DATA_DIR) do
      check_load
      check_errors
    end
  end

  def check_load
    code1 = %{
      def hello
        "password"
      end
    }

    code2 = %{
      def goodbye
        "bubbleboy"
      end
    }

    temp_file code1, "foo.rb" do |path|
      load "foo.rb"
      assert_equal "password", hello

      write_file path, code2

      LiveAST.load "foo.rb"
      assert_equal "bubbleboy", goodbye
    end
  ensure
    Object.send(:remove_method, :hello)
    Object.send(:remove_method, :goodbye)
  end

  def compare_load_errors(file)
    error = assert_raises LoadError do
      LiveAST.load file
    end
    assert_equal "cannot load such file -- #{file}", error.message
  end

  def check_errors
    temp_file "# do nothing", "foo.rb" do |_path|
      [
        "foo",
        "",
        "/usr",
        ".",
        "..",
      ].each do |file|
        compare_load_errors(file)
      end
    end
  end
end
