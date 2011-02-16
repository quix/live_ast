require_relative 'devel/jumpstart'

Jumpstart.new "live_ast" do |s|
  s.developer "James M. Lawrence", "quixoticsycophant@gmail.com"
  s.rubyforge_user = "quix"
  s.rubyforge_name = "liveast"
  s.camel_name = "LiveAST"
  s.rdoc_title = "LiveAST: Live Abstract Syntax Trees"
  
  # my code compensates for a ruby_parser bug; make this equal for now
  s.dependency("ruby_parser", "= 2.0.5")

  s.rdoc_files = %w[
    README.rdoc
    lib/live_ast/ast_eval.rb
    lib/live_ast/base.rb
    lib/live_ast/version.rb
  ]
end
