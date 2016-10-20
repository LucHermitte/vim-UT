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


# From cucumber/aruba project, licence MIT
# https://github.com/cucumber/aruba/
# File 'lib/aruba/matchers/file/be_an_existing_file.rb', line 18
RSpec::Matchers.define :be_an_existing_file do |_|
  match do |actual|
    # stop_processes!

    next false unless actual.is_a? String

    File.file?(actual)
  end

  failure_message do |actual|
    format("expected that file \"%s\" exists", actual)
  end

  failure_message_when_negated do |actual|
    format("expected that file \"%s\" does not exist", actual)
  end
end

