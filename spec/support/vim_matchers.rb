require 'vimrunner/rspec'
require 'rspec/expectations'
require 'support/vim'

RSpec::Matchers.define :be_successful do
  match do |actual|
    actual[1].empty? or expect(actual[0]).to eq 1
  end
  failure_message do |actual|
    # pp actual[1].empty?
    actual[1].join("\n")
  end
end

RSpec::Matchers.define :be_sourced do
  match do |actual|
    # actual[1].empty? or expect(actual[0]).to eq 1
    expect(vim.command("scriptnames")).to match(actual)
  end
  failure_message do |actual|
    # pp actual
    # pp actual[1].empty?
    "Script #{actual} hasn't been sourced. See:\n" + vim.command("scriptnames")
  end
end


