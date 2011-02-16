require_relative 'shared/main'

class DefineSingletonMethodTest < RegularTest
  def test_define_singleton_method
    a = Object.new
    a.define_singleton_method :f do |x, y|
      x + y
    end

    assert_equal 77, a.f(33, 44)

    assert_equal binop_define_singleton_method(:f, :+, :a),
                 a.singleton_class.instance_method(:f).to_ast
  end
end
