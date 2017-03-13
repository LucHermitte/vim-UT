require 'tmpdir'
require 'vimrunner'
require 'vimrunner/rspec'
require_relative './support/vim'
require 'rspec/expectations'
# require 'pp'
# require 'simplecov'

# SimpleCov.start

module Vimrunner
  class Client
    def runtime(script)
        script_path = Path.new(script)
        command("runtime #{script_path}")
    end
  end
end

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true
  vim_extra_plugins = []

  options = Dir.glob('./spec/extra_plugins.txt')
  options.each{ |opt_file|
    puts "  Reading option file #{opt_file}"
    IO.foreach(opt_file) do |line|
      # puts "    -> #{line}"
      if line =~ /^\s*#.*/ # ignore comments
      elsif line =~ /(\S+)\s* (\S+)/
        vim_extra_plugins += [ [$1, $2] ]
      else
        puts "    Error: cannot decode plugin path + name"
      end
    end
  }
  # pp vim_extra_plugins


  vim_plugin_path = File.expand_path('.')
  vim_flavor_path   = ENV['HOME']+'/.vim/flavors'

  config.start_vim do

    vim = Vimrunner.start_gvim
    # vim = Vimrunner.start_vim
    vim.add_plugin(vim_flavor_path, 'bootstrap.vim')
    vim.prepend_runtimepath(vim_plugin_path)

    vim_UT_path      = File.expand_path('../../../vim-UT', __FILE__)
    vim.add_plugin(vim_UT_path, 'plugin/UT.vim')

    vim_UT_path      = File.expand_path('../../../lh-vim-lib', __FILE__)
    vim.add_plugin(vim_UT_path, 'plugin/let.vim') # LetIfUndef

    # Extra plugins
    root_path = File.expand_path('../../../', __FILE__)
    vim_extra_plugins.each { |plugin|
      puts "    loading extra plugin: #{plugin[0]}/#{plugin[1]}"
      vim.add_plugin(root_path+plugin[0], plugin[1])
    }

    # pp vim_flavor_path
    pp vim.echo('&rtp')

    vim
  end
end

RSpec.configure do |config|
  config.include Support::Vim

  def write_file(filename, contents)
    dirname = File.dirname(filename)
    FileUtils.mkdir_p dirname if not File.directory?(dirname)

    File.open(filename, 'w') { |f| f.write(contents) }
  end
end

# vim:set sw=2:
