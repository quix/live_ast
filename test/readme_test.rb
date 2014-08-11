require_relative 'main'
require_relative '../devel/levitate'

if RUBY_ENGINE != "jruby" # jruby takes about a minute
  sections = [
    "Synopsis",
    "+to_ruby+",
    "Noninvasive Interface",
    "Pure Ruby and +ast_eval+",
    "Full Integration",
  ]

  Levitate.doc_to_test("README.rdoc", *sections)
end
