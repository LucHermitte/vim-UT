# encoding: UTF-8
require_relative './spec_helper_common'
require 'pp'
require 'support/vim_matchers'

RSpec.describe "unit tests" do
  # after(:all) do
    # vim.kill
  # end

  describe "Check dependent plugins are available", :deps => true do
      it "Has vim-UT" do
          expect(vim.echo('&rtp')).to match(/vim-UT/)
          expect(/plugin.UT\.vim/).to be_sourced
      end
  end

  describe "Check all tests", :unit_tests => true do
      pwd = Dir.pwd
      files = Dir.glob('./tests/**/*.vim')
      pp "In directory #{pwd}"
      files.each{ |file|
          it "[#{file}] runs fine" do
              # vim.command('call lh#UT#print_test_names()')
              vim.command('call lh#askvim#_beware_running_through_client_server()')
              abs_file = pwd + '/' + file
              log_file = abs_file + '.log'
              # log_file = '/tmp/'+ file + '.log'
              vim.command('call writefile(["test"], "'+log_file+'")')
              vim.command('call lh#log#set_logger("file", "'+log_file+'")')
              vim.command('call lh#log#this("Logging UT '+file+'")')
              # print "Check log file '#{log_file}' exists\n"
              expect(log_file).to be_an_existing_file
              result = vim.echo('lh#UT#check(0, "'+abs_file+'")')
              # pp "result: #{abs_file} -> #{result}"
              # Keep only the list =>
              if not (result.nil? or result.empty?)
                  # Clean echoed messages
                  result = eval(result.match(/\[\d,.*\]\]/)[0])
              end
              # pp "result0: #{result[0]}"
              if result.nil? or result.empty? or (result[0] == 0)
                  pp "Log: #{file}.log"
                  if File.file?(log_file)
                      log = File.read(log_file)
                      print "#{log}\n"
                  else
                      print "Warning: Cannot read #{log_file}\n"
                  end
              end
              expect(result).to_not be_nil
              expect(result).to be_successful
          end
      }
  end

end

# vim:set sw=2:
