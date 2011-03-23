require_relative 'main'

class AAA_LoadFileTest < BaseTest
  class << self
    attr_accessor :flag
  end

  def test_a_no_locals_created
    code = %{
      AAA_LoadFileTest.flag = :code_a
      FOO = 77
      x = 33
      y = 99
    }

    temp_file code do |file|
      ret = LiveAST.load file
      assert_equal true, ret
      assert_equal :code_a, AAA_LoadFileTest.flag
      
      assert_raises NameError do
        eval("x", TOPLEVEL_BINDING)
      end

      assert_equal 77, ::FOO
    end
  end

  def test_b_no_locals_modified
    code = %{
      AAA_LoadFileTest.flag = :code_b
      r = 55
    }

    temp_file code do |file|
      eval("r = 66", TOPLEVEL_BINDING)
      
      ret = LiveAST.load file
      assert_equal true, ret
      assert_equal :code_b, AAA_LoadFileTest.flag
      
      actual = eval("r", TOPLEVEL_BINDING)
      assert_equal 66, actual
    end
  end
  
  def test_c_wrap
    code = %{
      AAA_LoadFileTest.flag = :code_c
      ZOOM = 111
    }

    temp_file code do |file|
      ret = LiveAST.load file, true
      assert_equal true, ret
      assert_equal :code_c, AAA_LoadFileTest.flag
      
      assert_raises NameError do
        ZOOM
      end
    end
  end

  def self.from_d
    self.flag = :code_d
  end

  def test_d_empty_locals_list
    code = %{
      AAA_LoadFileTest.from_d
    }
    
    temp_file code do |file|
      LiveAST.load file
      assert_equal :code_d, AAA_LoadFileTest.flag
    end
  end
end
