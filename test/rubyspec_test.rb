require_relative 'main'
require_relative '../devel/levitate'

#
# Tests against rubyspec branch which discards '|ast@' tokens
#
class ZZZ_RubySpecTest < RegularTest
  FILES = [
    'core/basicobject/instance_eval_spec.rb',
    'core/binding/eval_spec.rb',
    'core/kernel/eval_spec.rb',
    'core/kernel/instance_eval_spec.rb',
    'core/module/class_eval_spec.rb',
    'core/module/module_eval_spec.rb',
  ]
  
  def setup
    super
    puts "\n==== rubyspec"
  end

  FILES.each do |file|
    mname = "test_" + file.gsub("/", "_").chop!.chop!.chop!
    define_method mname do
      Dir.chdir ENV["LIVE_AST_RUBYSPEC_HOME"] do
        cmd =
          ["mspec", "-t", Levitate.ruby_bin] +

          (["-T"]*Levitate.ruby_opts.size).
          zip(Levitate.ruby_opts).
          flatten +

          [file]

        assert system(*cmd)
      end
    end
  end
end if ENV["LIVE_AST_RUBYSPEC_HOME"]
