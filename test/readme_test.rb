require_relative 'main'
require_relative '../devel/jumpstart'

if LiveAST::Parser.respond_to?(:unified?) and LiveAST::Parser.unified?
  sections = [
    "Synopsis",
    "Loading Source",
    "Noninvasive Interface",
    "+to_ruby+",
  ]

  Jumpstart.doc_to_test("README.rdoc", *sections)
end
