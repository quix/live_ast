
class Jumpstart
  class Installer
    def initialize
      require 'fileutils'
      require 'rbconfig'
      require 'find'
      dest_root = RbConfig::CONFIG["sitelibdir"]
      sources = []
      Find.find("./lib") { |source|
        if install_file?(source)
          sources << source
        end
      }
      @spec = sources.inject(Array.new) { |acc, source|
        if source == "./lib"
          acc
        else
          dest = File.join(dest_root, source.sub(%r!\A\./lib!, ""))
  
          install = lambda {
            if File.directory?(source)
              unless File.directory?(dest)
                puts "mkdir #{dest}"
                FileUtils.mkdir(dest)
              end
            else
              puts "install #{source} --> #{dest}"
              FileUtils.install(source, dest)
            end
          }
            
          uninstall = lambda {
            if File.directory?(source)
              if File.directory?(dest)
                puts "rmdir #{dest}"
                FileUtils.rmdir(dest)
              end
            else
              if File.file?(dest)
                puts "rm #{dest}"
                FileUtils.rm(dest)
              end
            end
          }
  
          acc << {
            :source => source,
            :dest => dest,
            :install => install,
            :uninstall => uninstall,
          }
        end
      }
    end
  
    def install_file?(source)
      File.directory?(source) or
      (File.file?(source) and File.extname(source) == ".rb")
    end

    def install
      @spec.each { |entry|
        entry[:install].call
      }
    end
  
    def uninstall
      @spec.reverse.each { |entry|
        entry[:uninstall].call
      }
    end

    def run(args = ARGV)
      if args.empty?
        install
      elsif args.size == 1 and args.first == "--uninstall"
        uninstall
      else
        raise "unrecognized arguments: #{args.inspect}"
      end
    end
  end

  module AttrLazy
    def attr_lazy(name, &block)
      AttrLazy.define_reader(class << self ; self ; end, name, &block)
    end

    def attr_lazy_accessor(name, &block)
      attr_lazy(name, &block)
      AttrLazy.define_writer(class << self ; self ; end, name, &block)
    end

    class << self
      def included(mod)
        (class << mod ; self ; end).class_eval do
          def attr_lazy(name, &block)
            AttrLazy.define_reader(self, name, &block)
          end

          def attr_lazy_accessor(name, &block)
            attr_lazy(name, &block)
            AttrLazy.define_writer(self, name, &block)
          end
        end
      end

      def define_evaluated_reader(instance, name, value)
        (class << instance ; self ; end).class_eval do
          remove_method name rescue nil
          define_method name do
            value
          end
        end
      end

      def define_reader(klass, name, &block)
        klass.class_eval do
          remove_method name rescue nil
          define_method name do
            value = instance_eval(&block)
            AttrLazy.define_evaluated_reader(self, name, value)
            value
          end
        end
      end

      def define_writer(klass, name, &block)
        klass.class_eval do
          writer = "#{name}="
          remove_method writer rescue nil
          define_method writer do |value|
            AttrLazy.define_evaluated_reader(self, name, value)
            value
          end
        end
      end
    end
  end

  module Ruby
    module_function

    def executable
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

    def run(*args)
      cmd = [executable, *args]
      unless system(*cmd)
        cmd_str = cmd.map { |t| "'#{t}'" }.join(", ")
        raise "system(#{cmd_str}) failed with status #{$?.exitstatus}"
      end
    end

    def run_code_and_capture(code)
      IO.popen(%{"#{executable}"}, "r+") { |pipe|
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
      IO.popen(%{"#{executable}" "#{file}"}, "r") { |pipe|
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
  end

  module Util
    module_function

    def run_ruby_on_each(*files)
      files.each { |file|
        Ruby.run("-w", file)
      }
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
  end

  module InstanceEvalWithArgs
    module_function

    def with_temp_method(instance, method_name, method_block)
      (class << instance ; self ; end).class_eval do
        define_method(method_name, &method_block)
        begin
          yield method_name
        ensure
          remove_method(method_name)
        end
      end
    end

    def call_temp_method(instance, method_name, *args, &method_block)
      with_temp_method(instance, method_name, method_block) {
        instance.send(method_name, *args)
      }
    end

    def instance_eval_with_args(instance, *args, &block)
      call_temp_method(instance, :__temp_method, *args, &block)
    end
  end

  include AttrLazy
  include Util

  def initialize(project_name)
    $LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

    require 'rubygems/package_task'

    @project_name = project_name

    yield self

    self.class.instance_methods(false).select { |t|
      t.to_s =~ %r!\Adefine_!
    }.sort.each { |method_name|
      send(method_name)
    }
  end

  class << self
    alias_method :attribute, :attr_lazy_accessor
  end

  attribute :name do
    @project_name
  end

  attribute :version_constant_name do
    "VERSION"
  end

  attribute :camel_name do
    to_camel_case(name)
  end

  attribute :version do
    catch :bail do
      if File.file?(version_file = "./lib/#{name}/version.rb")
        require version_file
      elsif File.file?("./lib/#{name}.rb")
        require name
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

  attr_lazy :spec_output do
    "#{spec_output_dir}/#{spec_output_file}"
  end

  [:gem, :tgz].each { |ext|
    attribute ext do
      "pkg/#{name}-#{version}.#{ext}"
    end
  }

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

  attribute :readme_file do
    "README.rdoc"
  end
    
  attribute :manifest_file do
    "MANIFEST"
  end

  attribute :generated_files do
    []
  end

  attribute :files do
    if File.file? manifest_file
      File.read(manifest_file).split("\n")
    elsif source_control?
      IO.popen("git ls-files") { |pipe| pipe.read.split "\n" }
    end.to_a + [manifest_file] + generated_files
  end

  def files_in_require_paths
    require_paths.inject([]) { |acc, dir|
      acc + Dir.glob("#{dir}/**/*.rb")
    }
  end

  attribute :rdoc_files do
    files_in_require_paths
  end
    
  attribute :rdoc_title do
    "#{name}: #{summary}"
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
    File.file?(readme_file) ? [readme_file] : []
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
      g.has_rdoc = true
      %w[
        name
        authors
        email
        summary
        version
        description
        files
        rdoc_options
        extra_rdoc_files
        require_paths
      ].each { |param|
        value = send(param) and (
          g.send("#{param}=", value)
        )
      }

      g.homepage = url if url

      dependencies.each { |dep|
        g.add_dependency(*dep)
      }

      development_dependencies.each { |dep|
        g.add_development_dependency(*dep)
      }
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
        split(%r!\.\s*!m).
        first(send("#{section}_sentences")).
        join(".  ") << "."
      rescue
        "FIXME: #{section}"
      end
    end
  }

  attribute :url do
    "http://#{github_user}.github.com/#{name}"
  end

  attribute :github_user do
    raise "github_user not set"
  end

  attribute :authors do
    developers.map { |d| d[0] }
  end

  attribute :email do
    developers.map { |d| d[1] }
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

  def define_clean
    require 'rake/clean'
    task :clean do 
      Rake::Task[:clobber].invoke
    end
  end

  def define_package
    if source_control?
      task manifest_file do
        create_manifest
      end
      CLEAN.add manifest_file
      task :package => :clean
      Gem::PackageTask.new(gemspec).define
    end
  end

  def define_spec
    unless spec_files.empty?
      Ruby.no_warnings {
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
        run_ruby_on_each(*spec_files)
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
        run_ruby_on_each(*test_files)
      end
      
      task :prerelease => [:test, :test_deps]
      task :default => :test
      
      CLEAN.add cov_dir
    end
  end

  def define_doc
    desc "run rdoc"
    task :doc => :clean_doc do
      Kernel.send :gem, 'rdoc' rescue nil
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
        git "push", "-f", "origin", "gh-pages"
      end
    end
  end

  def define_install
    desc "direct install (no gem)"
    task :install do
      Installer.new.run([])
    end

    desc "direct uninstall (no gem)"
    task :uninstall do
      Installer.new.run(["--uninstall"])
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
      %w[github.com].each { |server|
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
      }
    end
  end

  def git(*args)
    sh "git", *args
  end

  def create_manifest
    write_file(manifest_file) {
      files.sort.join("\n")
    }
  end

  def define_release
    task :prerelease => [:clean, :check_directory, :ping, history_file]

    task :finish_release do
      git "tag", "#{name}-" + version.to_s
      git "push", "--tags", "origin", "master"
      sh "gem", "push", gem
    end

    task :release => [:prerelease, :package, :finish_release]
  end

  def define_debug_gem
    task :debug_gem do
      puts gemspec.to_ruby
    end
  end
  
  def open_browser(*files)
    sh(*([browser].flatten + files))
  end

  def suppress_task_warnings(*task_names)
    task_names.each { |task_name|
      Rake::Task[task_name].actions.map! { |action|
        lambda { |*args|
          Ruby.no_warnings {
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

  class << self
    include Util
    include InstanceEvalWithArgs

    # From minitest, part of the Ruby source; by Ryan Davis.
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
        rescue Exception => __jumpstart_exception
          puts "raises \#{__jumpstart_exception.class}"
        end
      }
      final_code = header + code + footer

      # Sometimes code is required to be inside a file.
      actual = nil
      require 'tempfile'
      Tempfile.open("run-rdoc-code") { |temp_file|
        temp_file.print(final_code)
        temp_file.close
        actual = Ruby.run_file_and_capture(temp_file.path).chomp
      }

      instance_eval_with_args(instance, expected, actual, index, &block)
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
          run_doc_code(code, expected, index, instance, &block)
          index += 1
        }
      else
        raise "couldn't find section `#{section}' of `#{file}'"
      end
    end

    def doc_to_spec(file, *sections, &block)
      jump = self
      describe file do
        sections.each { |section|
          describe "section `#{section}'" do
            it "should run as claimed" do
              if block
                jump.run_doc_section(file, section, self, &block)
              else
                jump.run_doc_section(file, section, self) {
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
      jump = self
      klass = Class.new MiniTest::Unit::TestCase do
        sections.each { |section|
          define_method "test_#{file}_#{section}" do
            if block
              jump.run_doc_section(file, section, self, &block)
            else
              jump.run_doc_section(file, section, self) {
                |expected, actual, index|
                assert_equal expected, actual
              }
            end
          end
        }
      end
      Object.const_set("Test#{file}".gsub(".", ""), klass)
    end
  end
end
