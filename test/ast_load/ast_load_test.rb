require 'main'

require 'live_ast/ast_load'

class AstLoadTest < BaseTest
  include FileUtils

  def test_defines_ast_load
    assert private_methods.include?(:ast_load)
  end

  def test_reloading
    noninvasive_ast_reload
  end

  def noninvasive_ast_reload
    code1 = %{
      class AstLoadTest::B
        def f
          "first B#f"
        end
      end
    }

    code2 = %{
      class AstLoadTest::B
        def f
          "second B#f"
        end
      end
    }

    temp_file code1 do |file|
      load file

      LiveAST.ast(B.instance_method(:f))

      write_file file, code2
      ast_load file

      assert_equal no_arg_def(:f, "second B#f"),
                   LiveAST.ast(B.instance_method(:f))
    end
  end
end
