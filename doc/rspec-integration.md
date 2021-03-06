## Integrating vim-UT with rspec+vimrunner

The couple rspec + [vimrunner](http://github.com/AndrewRadev/vimrunner) permits
to test vim plugins from ruby (rspec) scripts, and to integrate those tests in
travis-ci.

I provide a few files in order to automatically run vim-UT tests located in
`{yourpluginpath}/test/{whatever}/*.vim`.

### tl;dr

You'll need a `VimFlavor` file in your `{yourpluginpath}/test` directory that
contains.
```
flavor 'LucHermitte/vim-UT', '>= 0.3.0'
```
Note: you don't want to have your plugin to always depend on vim-UT. Only your
tests will need it.

__Beware, VimFlavor won't clone from `master` but from the last known tag. I've
lost days trying to figure out why tests were failing because of that.__

In your Rakefile, you'll have to add

```Rakefile
task :spec do
  # 'spec' is implicitly run as well
  sh "rspec ~/.vim-flavor/repos/LucHermitte_vim-UT/spec/UT_spec_v2.rb"
end

task :install do
  # The following line is required if your plugin depends on other plugins and
  # if you are using vim-flavor to manage dependencies.
  sh 'cat VimFlavor >> tests/VimFlavor'
  sh 'cd tests && bundle exec vim-flavor install'
end
```

You'll also need to inject the correct `LOAD_PATH` to rspec
```.rspec
--color
--format documentation
-I ~/.vim-flavor/repos/LucHermitte_vim-UT/spec
```

You'll also need a `spec_helper.rb` file in your `spec` directory. The file can
be empty.

If your tests requires a plugin that is not loaded by default, add a file named
`extra_plugins.txt` in `spec` directory that has on each line: the name of the
plugin suite, and the path to the script to source with `:runtime`.

_Et voilà!_


### Complete configuration

Here is a more complete set of files I use

#### `tests/VimFlavor`

```
flavor 'LucHermitte/vim-UT', '>= 0.3.0'
```

#### `Rakefile`

```Rakefile
#!/usr/bin/env rake

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :ci => [:dump, :install, :test]

task :default => :spec

task :dump do
  sh 'vim --version'
end

task :test    => :spec

task :spec do
  # 'spec' is implicitly run as well
  sh 'rspec ~/.vim-flavor/repos/LucHermitte_vim-UT/spec/UT_spec_v2.rb'
end


task :install do
  sh 'cat VimFlavor >> tests/VimFlavor'
  sh 'cd tests && bundle exec vim-flavor install'
end
```

#### `Gemfile`

```Gem
source 'https://rubygems.org'

gem 'rspec', '~> 3.1.0'
gem 'vimrunner', '~> 0.3.1'
gem 'rake', '~> 10.3.2'
gem 'vim-flavor', '~> 2.1.1'
```

#### `.travis.yml`

```yml
language: ruby
cache: bundler
sudo: false
addons:
  apt:
    packages:
      - vim-gtk
rvm:
  - 2.1.5 # vim-flavor requires a recent version of ruby
script: bundle exec rake ci
before_script:
  - "export DISPLAY=:99.0"
  - "sh -e /etc/init.d/xvfb start"
```

#### `.rspec`
```.rspec
--color
--format documentation
-I ~/.vim-flavor/repos/LucHermitte_vim-UT/spec
```

#### `extra_plugins.txt`
For instance,
```
# Definition of :AddStyle
lh-dev plugin/dev.vim
```

#### `spec/flavor.vimrc`

In case you need to make sure some things are defined as they would have been
with a `.vimrc`, define this file.

Note: with vim-flavor v2, it shall source `~/.vim/flavors/bootstrap.vim`.
vim-flavor v3 stores plugins into "start" package directory, but the rspec
scripts provided are not yet compatible with vim-flavor v3.
See [`:h load-plugins`](http://vimhelp.appspot.com/starting.txt.html#load%2dplugins).

### Notes

I know, vim-flavor or vim-runner are enough and don't require another unit
testing plugin. The thing is I've started vim-UT long before those solutions
came into existence and I already have a few unit tests written.

I've integrated vim-runner in my tests because I like the way it permits to
test plugin outputs, and because it's easy to integrate with travis-ci.

I've integrated vim-flavor for its simplicity to manage dependencies from
travis-ci.

And I'll continue to write unit tests for vim-UT because it fills the quickfix
window with the assertions failed, and even with the callstack in case of
uncaught exceptions. Then, I can easily navigate to the failed assertion and
run expression or debug them with my `CTRL-L-x`,`CTRL-L-e`, and `CTRL-L-d`
mappings from
[`vim_set` ftplugin](http://github.com/LucHermitte/lh-misc/tree/master/ftplugin/vim_set.vim).

Note that since vim-UT V2, `UT_spec_v2.rb`, doesn't require vim-runner. It only
requires rspec.  But beware of
[`feedkeys()`](http://vimhelp.appspot.com/eval.txt.html#feedkeys%28%29) or
[`:normal`](http://vimhelp.appspot.com/various.txt.html#%3anormal) when
testing mappings or abbreviations.
