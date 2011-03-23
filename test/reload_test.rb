require_relative 'main'

class AAB_ReloadTest < BaseTest
  include FileUtils

  def test_reloading
    raw_reload
    require 'live_ast/ast_load'
    noninvasive_ast_reload
    require 'live_ast/replace_load'
    ast_reload
  end

  def raw_reload
    code_1 = %{
      class AAB_ReloadTest::A
        def f
          "first A#f"
        end
      end
    }
  
    code_2 = %{
      class AAB_ReloadTest::A
        def f
          "second A#f"
        end
      end
    }

    temp_file code_1 do |file|
      load file

      LiveAST.ast(A.instance_method(:f))

      write_file file, code_2
      load file

      # forced a raw-reload inconsistency -- verify bogus

      assert_equal no_arg_def(:f, "first A#f"),
                   LiveAST.ast(A.instance_method(:f))
    end
  end

  def noninvasive_ast_reload
    code_1 = %{
      class AAB_ReloadTest::B
        def f
          "first B#f"
        end
      end
    }

    code_2 = %{
      class AAB_ReloadTest::B
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

  def ast_reload
    code_1 = %{
      class AAB_ReloadTest::C
        def f
          "first C#f"
        end
      end
    }

    code_2 = %{
      class AAB_ReloadTest::C
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
