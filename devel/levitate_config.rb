
if RUBY_ENGINE == "jruby"
  Levitate.ruby_opts = %w[--1.9 -J-Djruby.astInspector.enabled=false]
end
