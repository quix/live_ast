class Levitate
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

    def doc_to_test(file, *sections, &block)
      levitate = self
      klass = Class.new MiniTest::Test do
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
end

lambda do
  config = File.join(File.dirname(__FILE__), "levitate_config.rb")
  require config if File.file? config
end.call
