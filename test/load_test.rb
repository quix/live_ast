require_relative 'shared/main'

class AAA_LoadFileTest < BaseTest
  class << self
    attr_accessor :flag
  end

  include FileUtils

  FILENAME_A = DATA_DIR + "/load_test_data_a.rb"
  FILENAME_B = DATA_DIR + "/load_test_data_b.rb"
  FILENAME_C = DATA_DIR + "/load_test_data_c.rb"
  FILENAME_D = DATA_DIR + "/load_test_data_d.rb"

  def setup
    super
    mkdir_p DATA_DIR, :verbose => false
  end

  def teardown
    unless defined? SimpleCov
      rm_f FILENAME_A, :verbose => false
      rm_f FILENAME_B, :verbose => false
      rm_f FILENAME_C, :verbose => false
      rm_f FILENAME_D, :verbose => false
      rmdir DATA_DIR, :verbose => false
    end
    super
  end

  CODE_A = %{
    AAA_LoadFileTest.flag = :code_a
    FOO = 77
    x = 33
    y = 99
  }

  def test_a_no_locals_created
    File.open(FILENAME_A, "w") { |f| f.puts CODE_A }

    ret = LiveAST.load FILENAME_A
    assert_equal true, ret
    assert_equal :code_a, AAA_LoadFileTest.flag

    assert_raise NameError do
      eval("x", TOPLEVEL_BINDING)
    end

    assert_equal 77, ::FOO
  end

  CODE_B = %{
    AAA_LoadFileTest.flag = :code_b
    r = 55
  }

  def test_b_no_locals_modified
    eval("r = 66", TOPLEVEL_BINDING)

    File.open(FILENAME_B, "w") { |f| f.puts CODE_B }

    ret = LiveAST.load FILENAME_B
    assert_equal true, ret
    assert_equal :code_b, AAA_LoadFileTest.flag

    actual = eval("r", TOPLEVEL_BINDING)
    assert_equal 66, actual
  end
  
  CODE_C = %{
    AAA_LoadFileTest.flag = :code_c
    ZOOM = 111
  }

  def test_c_wrap
    File.open(FILENAME_C, "w") { |f| f.puts CODE_C }

    ret = LiveAST.load FILENAME_C, true
    assert_equal true, ret
    assert_equal :code_c, AAA_LoadFileTest.flag
    
    assert_raises NameError do
      ZOOM
    end
  end

  def self.from_d
    self.flag = :code_d
  end

  CODE_D = %{
    AAA_LoadFileTest.from_d
  }

  def test_d_empty_locals_list
    File.open(FILENAME_D, "w") { |f| f.puts CODE_D }
    LiveAST.load FILENAME_D
    assert_equal :code_d, AAA_LoadFileTest.flag
  end
end
