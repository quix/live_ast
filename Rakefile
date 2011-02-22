require_relative 'devel/jumpstart'

Jumpstart.new "live_ast" do |s|
  s.developers << ["James M. Lawrence", "quixoticsycophant@gmail.com"]
  s.github_user = "quix"

  s.camel_name = "LiveAST"

  s.rdoc_title = "LiveAST: Live Abstract Syntax Trees"
  s.rdoc_files = %w[
    lib/live_ast/ast_eval.rb
    lib/live_ast/base.rb
    lib/live_ast/to_ast.rb
    lib/live_ast/to_ruby.rb
    lib/live_ast/version.rb
  ]
  s.rdoc_options << "-a"
  
  # my code compensates for a ruby_parser bug; make this equal for now
  s.dependencies << ["ruby_parser", "= 2.0.6"]

  s.development_dependencies << ["ruby2ruby"]
end
