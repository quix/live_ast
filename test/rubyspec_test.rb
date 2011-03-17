require_relative 'main'
require_relative '../devel/levitate'

class ZZZ_RubySpecTest < ReplaceEvalTest
  def setup
    super
    puts "\n==== rubyspec"
  end

  FILES = [
    'core/basicobject/instance_eval_spec.rb',
    'core/binding/eval_spec.rb',
    'core/kernel/eval_spec.rb',
    'core/kernel/instance_eval_spec.rb',
    'core/module/class_eval_spec.rb',
    'core/module/module_eval_spec.rb',
  ]

  def test_rubyspec
    Dir.chdir(ENV["RUBYSPEC_HOME"] || "../rubyspec") do
      FILES.each do |file|
        cmd = %w[mspec -I../live_ast/lib -t] + [Levitate.ruby_bin, file]
        assert system(*cmd)
      end
    end
  end
end if [ENV["USER"], ENV["USERNAME"]].include? "jlawrence"
