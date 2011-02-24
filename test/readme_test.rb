require_relative 'main'
require_relative '../devel/jumpstart'

if LiveAST.parser.respond_to?(:unified?) and LiveAST.parser.unified?
  sections = [
    "Synopsis",
    "Loading Source",
    "Noninvasive Interface",
    "+to_ruby+",
  ]

  Jumpstart.doc_to_test("README.rdoc", *sections)
end
