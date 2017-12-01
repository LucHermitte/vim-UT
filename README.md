# vim-UT [![Last release](https://img.shields.io/github/tag/LucHermitte/vim-UT.svg)](https://github.com/LucHermitte/vim-UT/releases) [![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)

## Introduction

_UT_ is another Test Unit Framework for Vim, which main particularity is to fill the |quickfix| window with the assertion failures.

## Features
  * Assertion failures are reported in the quickfix window
  * Assertion syntax is simple, check Tom Link's suite, it's the same
  * Supports banged `:Assert!` to stop processing a given test on failed assertions
  * All the `s:Test*` functions of a suite are executed (almost) independently (i.e., a critical `:Assert!` failure will stop the Test of the function, and `lh#UT` will proceed to the next `s:Test` function
  * Lightweight and simple to use: there is only one command defined, all the other definitions are kept in an autoload plugin.
  * A suite == a file
  * Several `s:TestXxx()` per suite
  * +optional `s:Setup()`, `s:Teardown()`
  * Supports `:Comments`
  * `s:LocalFunctions()`, `s:variables`, and `l:variables` are supported
  * Takes advantage of [BuildToolsWrapper](http://github.com/LucHermitte/vim-build-tools-wrapper)'s `:COpen` command if installed
  * Count successful tests and failed assertions
  * Short-cuts to run the Unit Tests associated to a given vim script; Relies on: [Let-Modeline](http://github.com/LucHermitte/lh-misc/blob/master/plugin/let-modeline.vim)/[local\_vimrc](http://github.com/LucHermitte/local_vimrc)/[Project](http://www.vim.org/scripts/script.php?script_id=69) to set `g:UTfiles` (space separated list of glob-able paths), and on [`lh-vim-lib#path`](http://github.com/LucHermitte/lh-vim-lib)
  * Command to exclude, or specify the tests to play => `:UTPlay`, `UTIgnore`
  * [Helper scripts](doc/rspec-integration.md) are provided to help integration
    with vimrunner+rspec. See examples of use in
    [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib) and
    [lh-brackets](http://github.com/LucHermitte/lh-brackets).
  * Callstack is decoded and expanded in the quickfix window on uncaught
    exceptions.

#### Usage
  * Create a new vim script, it will be a Unit Testing Suite.
  * One of the first lines must contain
```
UTSuite Some intelligible name for the suite
```
  * Then you are free to directly assert anything you wish as long as it is a valid vim |expression|, e.g.
```
Assert 1 > 2
Assert 1 > 0
Assert s:foo > s:Bar(g:var + 28) / strlen("foobar")

AssertTxt! (s:foo > s:Bar(g:var+28),
        \, s:foo." isn't bigger than s:Bar(".g:var."+28)")
AssertEquals('a', 'a')
AssertDiffers('a', 'b')
let dict = {}
AssertIs(dict, dict)
AssertMatch('abc', 'a')
AssertRelation(1, '<', 2)
AssertThrows 0 + [0]
```
  * or to define as many independent tests as you wish. A test is a function with a name starting with `s:Test`. Even if a test critically fails, the next test will be executed, e.g.
```
function s:Test1()
  let var = SomeFunction()
  Assert! type(var) == type(0)
  Assert var < 42
  Assert! var > 0

  " Some other code that won't be executed if the previous assertion failed
  " /*the wiki does not recognizes vim comments*/
  let i = var / 42.0
  Comment This comment may never be displayed if {var} is negative or not a number
endfunction

function s:Test2()
  Assert s:what != Ever()
endfunction
```
  * If you wish to see a set-up function executed before each test, define the `s:Setup()` function.
  * If you wish to see a clean-up function executed after each test, define the `s:Teardown()` function.
  * Now run `:UTRun` of your test script (filename), and ... debug your failed assertions.

##### Examples
See:
  * [tests/lh/UT.vim](tests/lh/UT.vim) for a classical test,
  * [tests/lh/UT-fixtures.vim](tests/lh/UT-fixtures.vim) for a test with fixtures.


#### To Do
  * Add `&efm` for VimL errors like the one produced by `:Assert 0 + [0]`
  * Check UT works fine under windows (where paths have spaces, etc.), and on UTF-8 files
  * Simplify `s:errors` functions
  * Merge with Tom Link's tAssert plugin? (the UI is quite different)
  * Support Embedded comments like for instance:
```
Assert 1 == 1 " 1 must value 1
```
  * Ways to test buffers produced
  * Always execute s:Teardown() -- move its call to a :finally bloc
  * Find a way to prevent the potential script scope pollution


## Design Choices
  * The assertions supported by this plugin are expected to be made in a Unit Testing file, they are not to be used in regular VimL scripts as a _Design by Contract_ tool. Check my [DbC framework](http://github.com/LucHermitte/lh-vim-lib/tree/master/doc/DbC.md) in lh-vim-lib, or even Thomas Link's plugin, it is much more suited for that kind of assertions.

  * In order to be able to produce the quickfix entries, the plugin first parses the Unit Test file to complete all `:Assert` occurrences with extra information about the line number where the assertion is made.


## Installation
  * Requirements: Vim 7.+, [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib) v4.0.0
  * With [vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), install vim-UT (this is the preferred method because of the dependencies)
```vim
ActivateAddons UT
```
  *  or with [vim-flavor](http://github.com/kana/vim-flavor), which also
     handles dependencies
```
flavor 'LucHermitte/vim-UT'
```
  * or you can clone the git repositories
```vim
git clone git@github.com:LucHermitte/lh-vim-lib.git
git clone git@github.com:LucHermitte/vim-UT.git
```
  * or with Vundle/NeoBundle:
```vim
Bundle 'LucHermitte/lh-vim-lib'
Bundle 'LucHermitte/vim-UT'
```

## Other Tests related plugins for Vim
  * Tom Link's [tAssert plugin](http://www.vim.org/scripts/script.php?script_id=1730), and [spec\_vim plugin](https://github.com/tomtom/spec_vim),
  * Staale Flock's [vimUnit plugin](http://www.vim.org/scripts/script.php?script_id=1125),
  * Meikel Brandmeyer's [vimTAP plugin](http://www.vim.org/scripts/script.php?script_id=2213),
  * Ben Fritz's [vim-2html-test](http://code.google.com/p/vim-2html-test/) plugin,
  * Ingo Karkat's [runVimTests plugin](http://www.vim.org/scripts/script.php?script_id=2565),
  * See also Paul Mucur article's: [Testing Vim Plugins on Travis CI with RSpec and Vimrunner](http://mudge.github.com/2012/04/18/testing-vim-plugins-on-travis-ci-with-rspec-and-vimrunner.html),
  * Andrew Radev's [vimrunner](http://github.com/AndrewRadev/vimrunner),
  * Kana's [vim-spec](http://github.com/kana/vim-spec)

