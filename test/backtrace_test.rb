require_relative 'main'

# test for raise redefinition side-effects: unsort this TestCase from
# other TestCases.

define_unsorted_test_case "BacktraceTest", RegularTest do
  def test_raise_in_eval
    3.times do
      orig = exception_backtrace do
        eval %{

          raise


        }, binding, "somewhere", 1000
      end

      live = exception_backtrace do
        ast_eval %{

          raise


        }, binding, "somewhere", 1000
      end

      assert_equal orig.first, live.first
      assert_match(/somewhere:1002/, live.first)
    end
  end

  def test_raise_no_overrides
    3.times do
      orig = exception_backtrace do
        eval %{


          raise

        }, binding, __FILE__, (__LINE__ + 9)
      end

      live = exception_backtrace do
        ast_eval %{


          raise

        }, binding
      end

      assert_equal orig.first, live.first
      here = Regexp.quote __FILE__
      assert_match(/#{here}/, live.first)
    end
  end

  def test_raise_using_overrides
    3.times do
      orig = exception_backtrace do
        eval %{


          raise

        }, binding, __FILE__, (__LINE__ + 9)
      end

      live = exception_backtrace do
        ast_eval %{


          raise

        }, binding, __FILE__, __LINE__
      end

      assert_equal orig.first, live.first
      here = Regexp.quote __FILE__
      assert_match(/#{here}/, live.first)
    end
  end

  def test_raise_using_only_file_override
    3.times do
      orig = exception_backtrace do
        eval %{


          raise

        }, binding, __FILE__
      end

      live = exception_backtrace do
        ast_eval %{


          raise

        }, binding, __FILE__
      end

      assert_equal orig.first, live.first
      here = Regexp.quote __FILE__
      assert_match(/#{here}/, live.first)
    end
  end

  def test_raise_after_eval
    raise_after_eval("raise", false)
    raise_after_eval("1/0", false)

    require 'live_ast/replace_raise'

    raise_after_eval("raise", true)
    raise_after_eval("1/0", false)
  end

  def raise_after_eval(code, will_succeed)
    3.times do
      orig = eval %{

        lambda { #{code} }


      }, binding, "somewhere", 1000

      live = ast_eval %{

          lambda { #{code} }


      }, binding, "somewhere", 1000

      orig_top = exception_backtrace { orig.call }.first
      live_top = exception_backtrace { live.call }.first

      assert_equal orig_top, LiveAST.strip_token(live_top)

      if will_succeed
        assert_equal orig_top, live_top
        assert_match(/somewhere:1002/, live_top)
      else
        assert_not_equal orig_top, live_top
        assert_match(/somewhere.*?:1002/, live_top)
      end
    end
  end

  def test_tokens_stripped
    lines = exception_backtrace do
      ast_eval %{ ast_eval %{ ast_eval %{raise}, binding }, binding }, binding
    end
    lines.each do |line|
      assert_nil line.index(LiveAST::Linker::REVISION_TOKEN)
    end
  end
end
