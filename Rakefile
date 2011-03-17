require_relative 'devel/levitate'

Levitate.new "live_ast" do |s|
  s.developers << ["James M. Lawrence", "quixoticsycophant@gmail.com"]
  s.username = "quix"
  s.rubyforge_info = ["quix", "liveast"]
  s.camel_name = "LiveAST"
  s.required_ruby_version = ">= 1.9.2"
  s.dependencies << ["live_ast_ruby_parser", ">= 0.6.0"]
  s.rdoc_title = "LiveAST: Live Abstract Syntax Trees"
  s.rdoc_files = %w[
    lib/live_ast/ast_eval.rb
    lib/live_ast/base.rb
    lib/live_ast/to_ast.rb
    lib/live_ast/to_ruby.rb
    lib/live_ast/version.rb
  ]
  s.rdoc_options << "-a"
end
