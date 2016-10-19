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
              vim.command('call lh#log#set_logger("file", "'+abs_file+'.log")')
              vim.command('call lh#log#this("Logging UT '+file+'")')
              result = vim.echo('lh#UT#check(0, "'+abs_file+'")')
              # Keep only the list
              pp "result: #{abs_file} -> #{result}"
              # Clean echoed messages
              if not result.nil?
                  result = eval(result.match(/\[\d,.*\]\]/)[0])
              end
              # pp "result0: #{result[0]}"
              if result.nil? or result.empty? or (result[0] == 0)
                  pp "Log: #{file}.log"
                  log = File.read(abs_file + '.log')
                  print "#{log}\n"
              end
              expect(result).to be_successful
          end
      }
  end

end

# vim:set sw=2:
