require 'main'

class ASTReloadTest < ReplaceEvalTest
  include FileUtils

  def test_reloading
    ast_reload
  end

  def ast_reload
    code_1 = %{
      class ASTReloadTest::C
        def f
          "first C#f"
        end
      end
    }

    code_2 = %{
      class ASTReloadTest::C
        def f
          "second C#f"
        end
      end
    }

    temp_file code_1 do |file|
      load file

      LiveAST.ast(C.instance_method(:f))

      write_file file, code_2
      load file

      assert_equal no_arg_def(:f, "second C#f"),
                   LiveAST.ast(C.instance_method(:f))
    end
  end
end
