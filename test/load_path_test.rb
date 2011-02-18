require_relative 'shared/main'

class AAA_LoadPathTest < BaseTest
  include FileUtils
  
  FILENAME = DATA_DIR + "/foo.rb"
  
  def setup
    super
    mkdir DATA_DIR, :verbose => false
  end

  def teardown
    unless defined?(SimpleCov)
      rm_f FILENAME, :verbose => false
      rmdir DATA_DIR, :verbose => false
    end
    Object.send(:remove_method, :hello) rescue nil
    Object.send(:remove_method, :goodbye) rescue nil
    super
  end

  CODE = %{
    def hello
      "password"
    end
  }

  def test_load_path
    $LOAD_PATH.unshift DATA_DIR
    begin
      run_load
    ensure
      $LOAD_PATH.shift
    end
  end
  
  def test_chdir
    Dir.chdir(DATA_DIR) do
      run_load
    end
  end

  def run_load
    File.open(FILENAME, "w") { |f| f.puts CODE }

    Object.send(:remove_method, :hello) rescue nil
    load "foo.rb"
    assert_equal "password", hello
    
    code = CODE.sub("hello", "goodbye").sub("password", "bubbleboy")
    File.open(FILENAME, "w") { |f| f.puts code }
      
    Object.send(:remove_method, :goodbye) rescue nil
    LiveAST.load "foo.rb"
    assert_equal "bubbleboy", goodbye
  end

  def test_errors
    File.open(FILENAME, "w") { |f| f.puts CODE }
    [
     "foo.rb",
     "foo",
     "/foo.rb",
     "",
     "/usr",
     ".",
     "..",
    ].each do |file|
      orig = assert_raise LoadError do
        load file
      end
      live = assert_raise LoadError do
        LiveAST.load file
      end
      assert_equal orig.message, live.message
    end
  end
end
