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
              abs_file = pwd + '/' + file
              result = vim.echo('lh#UT#check(0, "'+abs_file+'")')
              # Keep only the list
              # pp "result: #{abs_file} -> #{result}"
              # Clean echoed messages
              result = result.match(/\[\d,.*\]\]/)[0]
              expect(eval(result)).to be_successful
          end
      }
  end

end

# vim:set sw=2:
