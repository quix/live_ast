require 'main'

require 'live_ast/ast_load'

class AstLoadTest < BaseTest
  include FileUtils

  def test_reloading
    noninvasive_ast_reload
  end

  def noninvasive_ast_reload
    code_1 = %{
      class AstLoadTest::B
        def f
          "first B#f"
        end
      end
    }

    code_2 = %{
      class AstLoadTest::B
        def f
          "second B#f"
        end
      end
    }

    temp_file code_1 do |file|
      load file
    
      LiveAST.ast(B.instance_method(:f))
      
      write_file file, code_2
      ast_load file
      
      assert_equal no_arg_def(:f, "second B#f"),
                   LiveAST.ast(B.instance_method(:f))
    end
  end
end
