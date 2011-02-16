require_relative 'shared/main'

class StdlibTest < RegularTest
  def test_pp
    assert_not_nil method(:pp).to_ast
  end

  def test_find
    assert_not_nil Find.method(:find).to_ast
  end
end
