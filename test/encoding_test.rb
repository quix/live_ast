require_relative 'main'

require_relative 'encoding_test/default.rb'
require_relative 'encoding_test/usascii.rb'
require_relative 'encoding_test/utf8.rb'
require_relative 'encoding_test/utf8bom.rb'
require_relative 'encoding_test/utf8bom_only.rb'
require_relative 'encoding_test/usascii_with_utf8bom.rb'
require_relative 'encoding_test/koi8_with_utf8bom.rb'
require_relative 'encoding_test/cp932.rb'
require_relative 'encoding_test/eucjp.rb'
require_relative 'encoding_test/koi8.rb'
require_relative 'encoding_test/koi8_shebang.rb'

class AllEncodingTest < RegularTest
  include EncodingTest

  %w[

    default US-ASCII
    usascii US-ASCII
    utf8 UTF-8
    utf8bom UTF-8
    usascii_with_utf8bom US-ASCII
    koi8_with_utf8bom KOI8-R
    cp932 Windows-31J
    eucjp EUC-JP
    koi8 KOI8-R
    koi8_shebang KOI8-R

  ].each_slice(2) do |abbr, name|
    define_method "test_#{abbr}" do
      str = send("#{abbr}_string")
      assert_equal name, str.encoding.to_s

      ast = EncodingTest.instance_method("#{abbr}_string").to_ast
      assert_equal name, no_arg_def_return(ast).encoding.to_s
      
      LiveAST.load "./test/encoding_test/#{abbr}.rb"
      
      ast = EncodingTest.instance_method("#{abbr}_string").to_ast
      assert_equal name, no_arg_def_return(ast).encoding.to_s
    end
  end

  def test_bad
    orig = assert_raises ArgumentError do
      require "./test/encoding_test/bad.rb"
    end
    live = assert_raises ArgumentError do
      LiveAST.load "./test/encoding_test/bad.rb"
    end
    # inconsistent punctuation from Ruby
    re = %r!\Aunknown encoding name\s*[-:]\s*feynman-diagram\Z!
    assert_match re, orig.message
    assert_match re, live.message
  end
end
