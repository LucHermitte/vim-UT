# encoding: UTF-8
require 'pp'
# require 'rspec/expectations'

RSpec.describe "unit tests" do
  describe "Check all tests", :unit_tests => true do
      pwd = Dir.pwd
      files = Dir.glob('./tests/**/*.vim')
      pp "In directory #{pwd}, run #{files}"
      files.each{ |file|
          it "[#{file}] runs fine" do
              abs_file = pwd + '/' + file
              log_file = abs_file + '.log'
              # pp "file: #{file}"
              # pp "abs: #{abs_file}"
              # pp "log: #{log_file}"
              # TODO: inject precise plugins in runtimepath
              ok = system(%(vim -c "UTBatch #{log_file} #{abs_file}"))
              # print "Check log file '#{log_file}' exists\n"
              # expect(log_file).to be_an_existing_file
              if ! ok 
                # print "Log file: #{file}.log\n"
                if File.file?(log_file)
                  log = File.read(log_file)
                else
                  log = "Warning: Cannot read #{log_file}"
                end
              end
              expect(ok).to be_truthy, "expected test to succeed, got\n#{log}\n"
              ### log_file = '/tmp/'+ file + '.log'
              ##vim.command('call writefile(["test"], "'+log_file+'")')
              ##vim.command('call lh#log#set_logger("file", "'+log_file+'")')
              ##vim.command('call lh#log#this("Logging UT '+file+'")')
              ### print "Check log file '#{log_file}' exists\n"
              ##expect(log_file).to be_an_existing_file
              ##result = vim.echo('lh#UT#check(0, "'+abs_file+'")')
              ### pp "result: #{abs_file} -> #{result}"
              ### Keep only the list =>
              ##if not (result.nil? or result.empty?)
              ##    # Clean echoed messages
              ##    result = eval(result.match(/\[\d,.*\]\]/)[0])
              ##end
              ### pp "result0: #{result[0]}"
              ##if result.nil? or result.empty? or (result[0] == 0)
              ##    print "Log file: #{file}.log"
              ##    if File.file?(log_file)
              ##        log = File.read(log_file)
              ##        print "LOG: #{log}\n"
              ##    else
              ##        print "Warning: Cannot read #{log_file}\n"
              ##    end
              ##end
              ##expect(result).to_not be_nil
              ##expect(result).to be_successful
          end
      }
  end
end

# vim:set sw=2:
