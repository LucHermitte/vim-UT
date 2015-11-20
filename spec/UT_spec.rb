# encoding: UTF-8
require_relative './spec_helper_common'
require 'pp'

RSpec.describe "unit tests" do
  # after(:all) do
    # vim.kill
  # end

  describe "Check dependent plugins are available" do
      it "Has vim-UT" do
          expect(vim.echo('&rtp')).to match(/vim-UT/)
          expect(vim.command("scriptnames")).to match(/plugin.UT\.vim/)
      end
  end

  describe "Check all tests" do
      files = Dir.glob('./tests/**/*.vim')
      files.each{ |file|
          it "[#{file}] runs fine" do
              # vim.command('call lh#UT#print_test_names()')
              result = vim.echo('lh#UT#check(0, "'+file+'")')
              # Keep only the list
              # pp result
              # Clean echoed messages
              result = result.match(/\[\d,.*\]\]/)[0]
              expect(eval(result)).to be_successful
          end
      }
  end

end

# vim:set sw=2:
