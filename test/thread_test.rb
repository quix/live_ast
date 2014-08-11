require_relative 'main'

require 'thread'

class ThreadTest < RegularTest

  def test_threads
    klass = nil
    mutex = Mutex.new
    stop = false
    results = []
    num_threads = 50

    workers = (0...num_threads).map {
      Thread.new {
        until stop
          if klass
            found = klass.instance_method(:f).to_ast
            mutex.synchronize {
              results << found
            }
            break
          end
        end
      }
    }

    klass = Class.new do
      def f
        "anon#f"
      end
    end

    sleep(0.2)
    stop = true

    workers.each { |t| t.join }

    assert_equal num_threads, results.size
    results.each { |result|
      assert_equal no_arg_def(:f, "anon#f"), result
    }
  end
end
