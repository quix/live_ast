require_relative 'shared/main'

class AAB_ReloadTest < BaseTest
  include FileUtils

  FILENAME_A = DATA_DIR + "/reload_test_data_a.rb"
  FILENAME_B = DATA_DIR + "/reload_test_data_b.rb"
  FILENAME_C = DATA_DIR + "/reload_test_data_c.rb"

  def setup
    super
    mkdir_p DATA_DIR, :verbose => false
  end

  def teardown
    unless defined? SimpleCov
      rm_f FILENAME_A, :verbose => false
      rm_f FILENAME_B, :verbose => false
      rm_f FILENAME_C, :verbose => false
      rmdir DATA_DIR, :verbose => false
    end
    super
  end

  CODE_A1 = %{
    class AAB_ReloadTest::A
      def f
        "first A#f"
      end
    end
  }

  CODE_A2 = %{
    class AAB_ReloadTest::A
      def f
        "second A#f"
      end
    end
  }

  def test_reloading
    raw_reload
    require 'live_ast/ast_load'
    noninvasive_ast_reload
    require 'live_ast/replace_load'
    ast_reload
  end

  def raw_reload
    File.open(FILENAME_A, "w") { |f| f.puts CODE_A1 }
    load FILENAME_A

    LiveAST.ast(A.instance_method(:f))

    File.open(FILENAME_A, "w") { |f| f.puts CODE_A2 }
    load FILENAME_A

    # forced a raw-reload inconsistency -- verify bogus

    assert_equal no_arg_def(:f, "first A#f"),
                 LiveAST.ast(A.instance_method(:f))
  end
  CODE_B1 = %{
    class AAB_ReloadTest::B
      def f
        "first B#f"
      end
    end
  }

  CODE_B2 = %{
    class AAB_ReloadTest::B
      def f
        "second B#f"
      end
    end
  }

  def noninvasive_ast_reload
    File.open(FILENAME_B, "w") { |f| f.puts CODE_B1 }
    load FILENAME_B
    
    LiveAST.ast(B.instance_method(:f))

    File.open(FILENAME_B, "w") { |f| f.puts CODE_B2 }

    ast_load FILENAME_B

    assert_equal no_arg_def(:f, "second B#f"),
                 LiveAST.ast(B.instance_method(:f))
  end

  CODE_C1 = %{
    class AAB_ReloadTest::C
      def f
        "first C#f"
      end
    end
  }

  CODE_C2 = %{
    class AAB_ReloadTest::C
      def f
        "second C#f"
      end
    end
  }

  def ast_reload
    File.open(FILENAME_C, "w") { |f| f.puts CODE_C1 }
    load FILENAME_C
    
    LiveAST.ast(C.instance_method(:f))

    File.open(FILENAME_C, "w") { |f| f.puts CODE_C2 }

    load FILENAME_C

    assert_equal no_arg_def(:f, "second C#f"),
                 LiveAST.ast(C.instance_method(:f))
  end
end
