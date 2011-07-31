
class Levitate
  include Rake::DSL if defined? Rake::DSL

  def initialize(gem_name)
    @gem_name = gem_name

    $LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

    yield self

    self.class.instance_methods(false).sort.each do |name|
      if name.to_s =~ %r!\Adefine_!
        send(name)
      end
    end
  end

  attr_reader :gem_name

  def self.attribute(name, &block)
    var = :"@#{name}"
    define_method name do
      if instance_variable_defined?(var)
        instance_variable_get(var)
      else
        instance_variable_set(var, instance_eval(&block))
      end
    end
    attr_writer name
  end

  attribute :version_constant_name do
    "VERSION"
  end

  attribute :camel_name do
    to_camel_case(gem_name)
  end

  attribute :version do
    catch :bail do
      if File.file?(version_file = "./lib/#{gem_name}/version.rb")
        require version_file
      elsif File.file?("./lib/#{gem_name}.rb")
        require gem_name
      else
        throw :bail
      end
      mod = Kernel.const_get(camel_name)
      constants = mod.constants.map { |t| t.to_sym }
      unless constants.include?(version_constant_name.to_sym)
        throw :bail
      end
      mod.const_get(version_constant_name)
    end or "0.0.0"
  end

  attribute :required_ruby_version do
    ">= 0"
  end
  
  attribute :readme_file do
    "README.rdoc"
  end
  
  attribute :history_file do
    "CHANGES.rdoc"
  end
  
  attribute :doc_dir do
    "doc"
  end
  
  attribute :spec_files do
    Dir["./spec/*_{spec,example}.rb"]
  end
  
  attribute :test_files do
    (Dir["./test/test_*.rb"] + Dir["./test/*_test.rb"]).uniq
  end
  
  attribute :cov_dir do
    "coverage"
  end
  
  attribute :spec_output_dir do
    "rspec_output"
  end

  attribute :spec_output_file do
    "spec.html"
  end

  attribute :spec_output do
    "#{spec_output_dir}/#{spec_output_file}"
  end

  attribute :rcov_options do
    # workaround for the default rspec task
    Dir["*"].select { |f| File.directory? f }.inject(Array.new) { |acc, dir|
      if dir == "lib"
        acc
      else
        acc + ["--exclude", dir + "/"]
      end
    } + ["--text-report"]
  end

  attribute :generated_files do
    []
  end

  attribute :extra_gemspec do
    lambda { |spec| }
  end

  attribute :files do
    if source_control?
      IO.popen("git ls-files") { |pipe| pipe.read.split "\n" }
    end.to_a + generated_files
  end

  attribute :rdoc_files do
    files_in_require_paths
  end
    
  attribute :rdoc_title do
    "#{gem_name}: #{summary}".sub(/\.\Z/, "")
  end

  attribute :require_paths do
    ["lib"]
  end

  attribute :rdoc_options do
    if File.file?(readme_file)
      ["--main", readme_file]
    else
      []
    end + [
     "--title", rdoc_title,
    ] + (files_in_require_paths - rdoc_files).inject(Array.new) {
      |acc, file|
      acc + ["--exclude", file]
    }
  end

  attribute :extra_rdoc_files do
    [readme_file, history_file].select { |file| File.file?(file) }
  end

  attribute :browser do
    require 'rbconfig'
    if RbConfig::CONFIG["host"] =~ %r!darwin!
      "open"
    else
      "firefox"
    end
  end

  attribute :gemspec do
    Gem::Specification.new do |g|
      %w[
        summary
        version
        description
        files
        rdoc_options
        extra_rdoc_files
        require_paths
        required_ruby_version
      ].each do |param|
        t = send(param) and g.send("#{param}=", t)
      end
      g.name = gem_name
      g.homepage = url if url
      dependencies.each { |dep|
        g.add_dependency(*dep)
      }
      development_dependencies.each { |dep|
        g.add_development_dependency(*dep)
      }
      g.authors = developers.map { |d| d[0] }
      g.email =   developers.map { |d| d[1] }
      extra_gemspec.call(g)
    end
  end

  attribute :readme_contents do
    File.read(readme_file) rescue "FIXME: readme_file"
  end
  
  attribute :sections do
    begin
      data = readme_contents.split(%r!^==\s*(.*?)\s*$!)
      pairs = data[1..-1].each_slice(2).map { |section, contents|
        [section.downcase, contents.strip]
      }
      Hash[*pairs.flatten]
    rescue
      nil
    end
  end

  attribute :description_section do
    "description"
  end

  attribute :summary_section do
    "summary"
  end

  attribute :description_sentences do
    1
  end

  attribute :summary_sentences do
    1
  end
  
  [:summary, :description].each { |section|
    attribute section do
      begin
        sections[send("#{section}_section")].
        gsub("\n", " ").
        split(%r!\.\s+!m).
        first(send("#{section}_sentences")).
        join(". ").
        concat(".").
        sub(%r!\.+\Z!, ".")
      rescue
        "FIXME: #{section}"
      end
    end
  }

  attribute :url do
    "http://#{username}.github.com/#{gem_name}"
  end

  attribute :username do
    raise "username not set"
  end

  attribute :rubyforge_info do
    nil
  end

  attribute :dependencies do
    []
  end

  attribute :development_dependencies do
    []
  end

  attribute :developers do
    []
  end

  attribute :remote_levitate do
    url = ENV["LEVITATE"] ||
      "https://raw.github.com/quix/levitate/master/levitate.rb"
    IO.popen("curl -s #{url}") { |f| f.read }
  end

  attribute :local_levitate do
    File.open(__FILE__, "rb") { |f| f.read }
  end

  #### tasks

  def define_clean
    require 'rake/clean'
    task :clean do 
      Rake::Task[:clobber].invoke
    end
  end

  def define_package
    if source_control?
      require 'rubygems/package_task'

      task :package => :clean
      Gem::PackageTask.new(gemspec).define
    end
  end

  def define_spec
    unless spec_files.empty?
      no_warnings {
        require 'spec/rake/spectask'
      }
      
      desc "run specs"
      Spec::Rake::SpecTask.new('spec') do |t|
        t.spec_files = spec_files
      end
    
      desc "run specs with text output"
      Spec::Rake::SpecTask.new('text_spec') do |t|
        t.spec_files = spec_files
        t.spec_opts = ['-fs']
      end
  
      desc "run specs with html output"
      Spec::Rake::SpecTask.new('full_spec') do |t|
        t.spec_files = spec_files
        t.rcov = true
        t.rcov_opts = rcov_options
        t.spec_opts = ["-fh:#{spec_output}"]
      end
      
      suppress_task_warnings :spec, :full_spec, :text_spec

      desc "run full_spec then open browser"
      task :show_spec => :full_spec do
        open_browser(spec_output, cov_dir + "/index.html")
      end

      desc "run specs individually"
      task :spec_deps do
        run_each_file(*spec_files)
      end

      task :prerelease => [:spec, :spec_deps]
      task :default => :spec

      CLEAN.add spec_output_dir
    end
  end

  def define_test
    unless test_files.empty?
      desc "run tests"
      task :test do
        test_files.each { |file| require file }

        # if we use at_exit hook instead, it won't run before :release
        MiniTest::Unit.new.run ARGV
      end
      
      desc "run tests with coverage"
      if ruby_18?
        task :full_test do
          verbose(false) {
            sh("rcov", "-o", cov_dir, "--text-report",
               *(test_files + rcov_options)
            )
          }
        end
      else
        task :full_test do
          rm_rf cov_dir
          require 'simplecov'
          SimpleCov.start do
            add_filter "test/"
            add_filter "devel/"
          end
          Rake::Task[:test].invoke
        end
      end
      
      desc "run full_test then open browser"
      task :show_test => :full_test do
        show = lambda { open_browser(cov_dir + "/index.html") }
        if ruby_18?
          show.call
        else
          SimpleCov.at_exit do
            SimpleCov.result.format!
            show.call
          end
        end
      end
      
      desc "run tests individually"
      task :test_deps do
        run_each_file(*test_files)
      end
      
      task :prerelease => [:test, :test_deps]
      task :default => :test
      
      CLEAN.add cov_dir
    end
  end

  def define_doc
    desc "run rdoc"
    task :doc => :clean_doc do
      gem 'rdoc' rescue nil
      require 'rdoc/rdoc'
      args = (
        gemspec.rdoc_options +
        gemspec.require_paths.clone +
        gemspec.extra_rdoc_files +
        ["-o", doc_dir]
      ).flatten.map { |t| t.to_s }
      RDoc::RDoc.new.document args
    end
    
    task :clean_doc do
      # normally rm_rf, but mimic rake/clean output
      rm_r(doc_dir) rescue nil
    end

    desc "run rdoc then open browser"
    task :show_doc => :doc do
      open_browser(doc_dir + "/index.html")
    end

    task :rdoc => :doc
    task :clean => :clean_doc
  end

  def define_publish
    if source_control?
      desc "publish docs"
      task :publish => [:clean, :check_directory, :doc] do
        current_branch = `git branch`[/^\* (\S+)$/, 1] or raise "??? branch"
        if rubyforge_info
          user, project = rubyforge_info
          Dir.chdir(doc_dir) do
            sh "scp", "-r",
               ".",
               "#{user}@rubyforge.org:/var/www/gforge-projects/#{project}"
          end
        end
        git "branch", "-D", "gh-pages"
        git "checkout", "--orphan", "gh-pages"
        FileUtils.rm ".git/index"
        git "clean", "-fdx", "-e", "doc"
        Dir["doc/*"].each { |path|
          FileUtils.mv path, "."
        }
        FileUtils.rmdir "doc"
        git "add", "."
        git "commit", "-m", "generated by rdoc"
        git "checkout", current_branch
        git "push", "-f", "origin", "gh-pages"
      end
    end
  end

  def define_install
    desc "direct install (no gem)"
    task :install do
      Installer.new.install
    end

    desc "direct uninstall (no gem)"
    task :uninstall do
      Installer.new.uninstall
    end
  end
  
  def define_check_directory
    task :check_directory do
      unless `git status` =~ %r!nothing to commit \(working directory clean\)!
        raise "directory not clean"
      end
    end
  end

  def define_ping
    task :ping do
      require 'rbconfig'
      [
       "github.com",
       ("rubyforge.org" if rubyforge_info),
      ].compact.each do |server|
        cmd = "ping " + (
          if RbConfig::CONFIG["host"] =~ %r!darwin!
            "-c2 #{server}"
          else
            "#{server} 2 2"
          end
        )
        unless `#{cmd}` =~ %r!0% packet loss!
          raise "No ping for #{server}"
        end
      end
    end
  end

  def define_check_levitate
    task :check_levitate do
      unless local_levitate == remote_levitate
        raise "levitate is out of date"
      end
    end
  end

  def define_update_levitate
    task :update_levitate do
      if local_levitate == remote_levitate
        puts "Already up-to-date."
      else
        File.open(__FILE__, "w") { |f| f.print(remote_levitate) }
        git "commit", __FILE__, "-m", "update tools"
        puts "Updated levitate."
      end
    end
  end

  def define_changes
    task :changes do
      if File.read(history_file).index version
        raise "version not updated"
      end

      header = "\n\n== Version #{version}\n\n"

      bullets = `git log --format=%s #{last_release}..HEAD`.lines.map { |line|
        "* #{line}"
      }.join.chomp

      write_file(history_file) do
        File.read(history_file).sub(/(?<=#{gem_name} Changes)/) {
          header + bullets
        }
      end
    end
  end

  def define_release
    task :prerelease => [
      :clean,
      :check_directory,
      :check_levitate,
      :ping,
      history_file
    ]

    task :finish_release do
      git "tag", "#{gem_name}-" + version.to_s
      git "push", "--tags", "origin", "master"
      sh "gem", "push", "pkg/#{gem_name}-#{version}.gem"
    end

    task :release => [:prerelease, :package, :finish_release, :publish]
  end

  def define_debug_gem
    task :debug_gem do
      puts gemspec.to_ruby
    end
  end

  #### helpers

  def files_in_require_paths
    require_paths.inject([]) { |acc, dir|
      acc + Dir.glob("#{dir}/**/*.rb")
    }
  end

  def last_release
    `git tag`.lines.select { |t| t.index(gem_name) == 0 }.last.chomp
  end

  def git(*args)
    sh "git", *args
  end

  def open_browser(*files)
    sh(*([browser].flatten + files))
  end

  def suppress_task_warnings(*task_names)
    task_names.each { |task_name|
      Rake::Task[task_name].actions.map! { |action|
        lambda { |*args|
          no_warnings {
            action.call(*args)
          }
        }
      }
    }
  end

  def ruby_18?
    RUBY_VERSION =~ %r!\A1\.8!
  end

  def source_control?
    File.directory? ".git"
  end

  #### utility for instance and class

  module Util
    def ruby_bin
      require 'rbconfig'

      name = File.join(
        RbConfig::CONFIG["bindir"],
        RbConfig::CONFIG["RUBY_INSTALL_NAME"]
      )

      if RbConfig::CONFIG["host"] =~ %r!(mswin|cygwin|mingw)! and
          File.basename(name) !~ %r!\.(exe|com|bat|cmd)\Z!i
        name + RbConfig::CONFIG["EXEEXT"]
      else
        name
      end
    end

    def ruby_command
      [ruby_bin] + Levitate.ruby_opts.to_a
    end

    def ruby_command_string
      ruby_command.join(" ")
    end

    def run(*args)
      cmd = ruby_command + args
      unless system(*cmd)
        cmd_str = cmd.map { |t| "'#{t}'" }.join(", ")
        raise "system(#{cmd_str}) failed with status #{$?.exitstatus}"
      end
    end

    def run_each_file(*files)
      files.each { |file|
        run("-w", file)
      }
    end

    def run_code_and_capture(code)
      IO.popen(ruby_command_string, "r+") { |pipe|
        pipe.print(code)
        pipe.flush
        pipe.close_write
        pipe.read
      }
    end

    def run_file_and_capture(file)
      unless File.file? file
        raise "file does not exist: `#{file}'"
      end
      IO.popen(ruby_command_string + " " + file, "r") { |pipe|
        pipe.read
      }
    end
      
    def with_warnings(value = true)
      previous = $VERBOSE
      $VERBOSE = value
      begin
        yield
      ensure
        $VERBOSE = previous
      end
    end
      
    def no_warnings(&block)
      with_warnings(nil, &block)
    end

    def to_camel_case(str)
      str.split('_').map { |t| t.capitalize }.join
    end

    def write_file(file)
      contents = yield
      File.open(file, "wb") { |out|
        out.print(contents)
      }
      contents
    end

    def instance_exec2(obj, *args, &block)
      method_name = ["_", obj.object_id, "_", Thread.current.object_id].join
      (class << obj ; self ; end).class_eval do
        define_method method_name, &block
        begin
          obj.send(method_name, *args)
        ensure
          remove_method method_name
        end
      end
    end
  end
  extend Util
  include Util

  #### public helpers for testing

  class << self
    # From 'minitest' by Ryan Davis.
    def capture_io
      require 'stringio'

      orig_stdout, orig_stderr         = $stdout, $stderr
      captured_stdout, captured_stderr = StringIO.new, StringIO.new
      $stdout, $stderr                 = captured_stdout, captured_stderr

      yield

      return captured_stdout.string, captured_stderr.string
    ensure
      $stdout = orig_stdout
      $stderr = orig_stderr
    end

    def run_doc_code(code, expected, index, instance, &block)
      lib = File.expand_path(File.dirname(__FILE__) + "/../lib")
      header = %{
        $LOAD_PATH.unshift "#{lib}"
        begin
      }
      footer = %{
        rescue Exception => __levitate_exception
          puts "raises \#{__levitate_exception.class}"
        end
      }
      final_code = header + code + footer

      # Sometimes code is required to be inside a file.
      actual = nil
      require 'tempfile'
      Tempfile.open("run-rdoc-code") { |temp_file|
        temp_file.print(final_code)
        temp_file.close
        actual = run_file_and_capture(temp_file.path).chomp
      }

      instance_exec2(instance, expected, actual, index, &block)
    end

    def run_doc_section(file, section, instance, &block)
      contents = File.read(file)
      re = %r!^=+[ \t]#{Regexp.quote(section)}.*?\n(.*?)^=!m
      if section_contents = contents[re, 1]
        index = 0
        section_contents.scan(%r!^(  \S.*?)(?=(^\S|\Z))!m) { |indented, unused|
          code_sections = indented.split(%r!^  \#\#\#\# output:\s*$!)
          code, expected = (
            case code_sections.size
            when 1
              [indented, indented.scan(%r!\# => (.*?)\n!).flatten.join("\n")]
            when 2
              code_sections
            else
              raise "parse error"
            end
          )
          code.gsub!(/^\s*%.*$/, "") # ignore shell command examples
          run_doc_code(code, expected, index, instance, &block)
          index += 1
        }
      else
        raise "couldn't find section `#{section}' of `#{file}'"
      end
    end

    def doc_to_spec(file, *sections, &block)
      levitate = self
      describe file do
        sections.each { |section|
          describe "section `#{section}'" do
            it "should run as claimed" do
              if block
                levitate.run_doc_section(file, section, self, &block)
              else
                levitate.run_doc_section(file, section, self) {
                  |expected, actual, index|
                  actual.should == expected
                }
              end
            end
          end
        }
      end
    end

    def doc_to_test(file, *sections, &block)
      levitate = self
      klass = Class.new MiniTest::Unit::TestCase do
        sections.each { |section|
          define_method "test_#{file}_#{section}" do
            if block
              levitate.run_doc_section(file, section, self, &block)
            else
              levitate.run_doc_section(file, section, self) {
                |expected, actual, index|
                assert_equal expected, actual
              }
            end
          end
        }
      end
      Object.const_set("Test#{file}".gsub(".", ""), klass)
    end

    def ruby_opts
      @ruby_opts ||= []
    end
    attr_writer :ruby_opts
  end

  #### raw install, bypass gems

  class Installer
    def initialize
      require 'fileutils'
      require 'rbconfig'
      require 'find'

      @fu = FileUtils::Verbose
      @spec = []

      rb_root = RbConfig::CONFIG["sitelibdir"]

      Find.find "lib" do |source|
        next if source == "lib"
        next unless File.directory?(source) || File.extname(source) == ".rb"
        dest = File.join(rb_root, source.sub(%r!\Alib/!, ""))
        @spec << [source, dest]
      end
    end

    def install
      @spec.each do |source, dest|
        if File.directory?(source)
          @fu.mkdir(dest) unless File.directory?(dest)
        else
          @fu.install(source, dest)
        end
      end
    end
  
    def uninstall
      @spec.reverse.each do |source, dest|
        if File.directory?(source)
          @fu.rmdir(dest) if File.directory?(dest)
        else
          @fu.rm(dest) if File.file?(dest)
        end
      end
    end
  end
end

lambda do
  config = File.join(File.dirname(__FILE__), "levitate_config.rb")
  require config if File.file? config
end.call
