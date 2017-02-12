require_relative 'main'

class AllEncodingTest < RegularTest
  ENC_TESTS = {
    default: "UTF-8",
    usascii: "US-ASCII",
    utf8: "UTF-8",
    utf8unix: "UTF-8",
    utf8mac: "UTF-8",
    utf8mac_alt: "UTF8-MAC",
    utf8dos: "UTF-8",
    utf8bom: "UTF-8",
    utf8bom_only: "UTF-8",
    usascii_with_utf8bom: "US-ASCII",
    koi8_with_utf8bom: "KOI8-R",
    cp932: "Windows-31J",
    eucjp: "EUC-JP",
    koi8: "KOI8-R",
    koi8_shebang: "KOI8-R"
  }.freeze

  ENC_TESTS.each_pair do |abbr, name|
    define_method "test_#{abbr}" do
      require_relative "encoding_test/#{abbr}"
      self.class.class_eval { include EncodingTest }

      str = send("#{abbr}_string")
      assert_equal name, str.encoding.to_s

      ast = EncodingTest.instance_method("#{abbr}_string").to_ast
      assert_equal "UTF-8", no_arg_def_return(ast).encoding.to_s

      LiveAST.load "./test/encoding_test/#{abbr}.rb"

      ast = EncodingTest.instance_method("#{abbr}_string").to_ast
      assert_equal "UTF-8", no_arg_def_return(ast).encoding.to_s
    end
  end

  def test_bad
    orig = assert_raises ArgumentError do
      live_ast_original_load "./test/encoding_test/bad.rb"
    end
    live = assert_raises ArgumentError do
      LiveAST.load "./test/encoding_test/bad.rb"
    end
    # inconsistent punctuation from Ruby
    re = /\Aunknown encoding name\s*[-:]\s*feynman-diagram\Z/
    assert_match re, orig.message
    assert_match re, live.message
  end
end
