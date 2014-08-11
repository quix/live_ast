require 'main'

class ReloadTest < BaseTest
  include FileUtils

  def test_reloading
    raw_reload
  end

  def raw_reload
    code_1 = %{
      class ReloadTest::A
        def f
          "first A#f"
        end
      end
    }

    code_2 = %{
      class ReloadTest::A
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
end
