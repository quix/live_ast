# encoding: us-ascii

module LiveAST
  module Reader
    UTF8_BOM = /\A\xef\xbb\xbf/
    MAGIC_COMMENT = /\A(?:#!.*?\n)?\s*\#.*(?:en)?coding\s*[:=]\s*([^\s;]+)/

    def self.read(file)
      contents = File.read(file, encoding: "BINARY")

      utf8 = contents.sub!(UTF8_BOM, "") ? "UTF-8" : nil

      # magic comment overrides BOM
      encoding = contents[MAGIC_COMMENT, 1] || utf8 || "US-ASCII"

      contents.force_encoding(strip_special(encoding))
    end

    def self.strip_special(encoding)
      if encoding =~ /\Autf8-mac\Z/i
        "UTF8-MAC"
      else
        encoding.sub(/-(unix|dos|mac)\Z/i, "")
      end
    end
  end
end
