require_relative 'main'
require_relative '../devel/levitate'

class LoadFileTest < BaseTest
  class << self
    attr_accessor :flag
  end

  def test_a_no_locals_created
    code = %{
      LoadFileTest.flag = :code_a
      FOO = 77
      x = 33
      y = 99
    }

    temp_file code do |file|
      ret = LiveAST.load file
      assert_equal true, ret
      assert_equal :code_a, LoadFileTest.flag

      assert_raises NameError do
        eval("x", TOPLEVEL_BINDING)
      end

      assert_equal 77, ::FOO
    end
  end

  def test_b_no_locals_modified
    code = %{
      LoadFileTest.flag = :code_b
      r = 55
    }

    temp_file code do |file|
      eval("r = 66", TOPLEVEL_BINDING)

      ret = LiveAST.load file
      assert_equal true, ret
      assert_equal :code_b, LoadFileTest.flag

      actual = eval("r", TOPLEVEL_BINDING)
      assert_equal 66, actual
    end
  end

  def test_c_wrap
    code = %{
      LoadFileTest.flag = :code_c
      ZOOM = 111
    }

    temp_file code do |file|
      ret = LiveAST.load file, true
      assert_equal true, ret
      assert_equal :code_c, LoadFileTest.flag

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
      LoadFileTest.from_d
    }

    temp_file code do |file|
      LiveAST.load file
      assert_equal :code_d, LoadFileTest.flag
    end
  end

  def test_verbose_respected
    lib = File.expand_path(File.dirname(__FILE__) + "/../lib")

    [
      # respects a loaded file setting $VERBOSE = true
      [
        "false",
        "true",
        lambda { |file|
          Levitate.run file
        }
      ],

      # unfixable: does not respect a loaded file setting $VERBOSE = nil
      [
        "true",
        "false",
        lambda { |file|
          unfixable do
            assert_nothing_raised do
              Levitate.run file
            end
          end
        }
      ]
    ].each do |main_value, loaded_value, action|
      loaded_code = %{
        $VERBOSE = #{loaded_value}
      }

      temp_file loaded_code do |loaded_file|
        main_code = %{
          $LOAD_PATH.unshift '#{lib}'
          require 'live_ast/base'
          toplevel_local = 444
          $VERBOSE = #{main_value}
          LiveAST.load '#{loaded_file}'
          $VERBOSE == #{loaded_value} or exit(1)
        }
        temp_file main_code, &action
      end
    end
  end
end
