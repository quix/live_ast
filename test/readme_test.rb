require_relative 'shared/main'
require_relative '../devel/jumpstart'

sections = [
  "Synopsis",
  "Loading Source",
  "Noninvasive Interface",
  "+to_ruby+",
]

Jumpstart.doc_to_test("README.rdoc", *sections)
