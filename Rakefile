require_relative 'devel/jumpstart'

Jumpstart.new "live_ast" do |s|
  s.developers << ["James M. Lawrence", "quixoticsycophant@gmail.com"]
  s.github_user = "quix"
  s.rubyforge_info = ["quix", "liveast"]
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
  
  s.dependencies << ["live_ast_ruby_parser", ">= 0.5.1"]
end
