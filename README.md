# vim-UT [![Last release](https://img.shields.io/github/tag/LucHermitte/vim-UT.svg)](https://github.com/LucHermitte/vim-UT/releases) [![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)

## Introduction

_UT_ is another Unit Testing Framework for Vim, which main particularity is to fill the [`quickfix`](http://vimhelp.appspot.com/quickfix.txt.html#quickfix) window with the assertion failures.

## Features

#### Main features

  * Assertion failures are reported in the [`quickfix`](http://vimhelp.appspot.com/quickfix.txt.html#quickfix) window
  * Meant to be simple to use
      * Simple assertion syntax (`:Assert expression`, `:AssertEquals(ref, expr)`...)
      * Supports `:Comments`
      * Automatic registration of test functions
          * All the `s:Test*` functions of a suite are executed (almost) independently (i.e., a critical `:Assert!` failure will stop the Test of the function, and `lh#UT` will proceed to the next `s:Test` function
      * A suite == a file
      * Several `s:TestXxx()` per suite
  * Callstack is decoded and expanded in the quickfix window on uncaught
    exceptions.

#### Other features
  * Lightweight and simple to use: there is only one command defined, all the other definitions are kept in an autoload plugin.
  * Fixtures:
    * optional `s:Setup()`, `s:Teardown()` executed before and after each test
    * optional `s:BeforeAll()`, `s:AfterAll()` executed once before and after all tests from a suite
  * Supports banged `:Assert!` to stop processing a given test on failed assertions
  * `s:LocalFunctions()`, `s:variables`, and `l:variables` are supported
  * Buffer content can be set -- with `:SetBufferContent`
  * Buffer content can be tested -- with `:AssertBufferMatches`
  * Count successful tests and failed assertions
  * Command to exclude, or specify the tests to play => `:UTPlay`, `UTIgnore`
  * Short-cuts to run the Unit Tests associated to a given vim script; Relies on: [Let-Modeline](http://github.com/LucHermitte/lh-misc/blob/master/plugin/let-modeline.vim)/[local\_vimrc](http://github.com/LucHermitte/local_vimrc)/[Project](http://www.vim.org/scripts/script.php?script_id=69) to set `g:UTfiles` (space separated list of glob-able paths), and on [`lh-vim-lib#path`](http://github.com/LucHermitte/lh-vim-lib)
  * [Helper scripts](doc/rspec-integration.md) are provided to help integration
    with vimrunner+rspec. See examples of use in
    [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib) and
    [lh-brackets](http://github.com/LucHermitte/lh-brackets).
  * Takes advantage of [BuildToolsWrapper](http://github.com/LucHermitte/vim-build-tools-wrapper)'s `:COpen` command if installed

## Usage

#### Start-up

  * Create a new vim script, it will be a Unit Testing Suite.
  * One of the first lines must contain

        ```
        UTSuite Some intelligible name for the suite
        ```

  * Then you are free to directly assert anything you wish as long as it is a valid vim [`expression`](http://vimhelp.appspot.com/eval.txt.html#expression), e.g.

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

  * Now run `:UTRun` on your test script (filename), and ... debug your failed assertions.

#### Fixtures

Code can be executed before and after each test function with the optional
special functions:

  * `s:Setup()`: set-up function executed __before each__ test
  * `s:Teardown()`: clean-up function executed __after each__ test
  * `s:BeforeAll()`: set-up function execute once __before all__ tests from a suite
  * `s:AfterAll()`: clean-up function execute once __after all__ tests from a suite

#### Test on buffers

Most `:AssertXxx` commands are dedicated to unit testing vim functions. A
function returns a result and we test whether its value _equals_, _differs_,
_matches_, _is_...

Since V2, it's now possible set the content of a buffer before transforming it,
and to test whether the new buffer state is as expected.

Within the quickfix-window, we can hit `D` on the message associated to a
buffer matching failure in order to display, in a new
[`tabpage`](http://vimhelp.appspot.com/tabpage.txt.html#tabpage), the expected
content alongside the expected content in
[`diff-mode`](http://vimhelp.appspot.com/diff.txt.html#diff%2dmode).

The diff-mode can be exited by hitting `q` from any scratch buffer involded.

```vim
silent! call lh#window#create_window_with('new') " work around possible E36
try
    SetBufferContent a/file/name.txt
    %s/.*/\U&/
    AssertBufferMatch a/file/NAME.txt
finally
    bw
endtry
```

Or, with [`:let=<<`](http://vimhelp.appspot.com/eval.txt.html#%3alet%3d%3c%3c)
syntax

```vim
silent! call lh#window#create_window_with('new') " work around possible E36
try
    SetBufferContent << trim EOF
    1
    3
    2
    EOF

    %sort

    AssertBufferMatch << trim EOF
    1
    2
    3
    EOF
finally
    bw
endtry
```

__Note__: `:SetBufferContent` and `:AssertBufferMatch` with `<< [trim] EOF`
syntax can only be used within `s:TestXxx` functions.

#### Examples
See:
  * [tests/lh/UT.vim](tests/lh/UT.vim) for a classical test,
  * [tests/lh/UT-fixtures.vim](tests/lh/UT-fixtures.vim) for a test with fixtures.
  * [tests/lh/UT-buf.vim](tests/lh/UT-buf.vim) for tests on buffer content.


## To Do
  * Check UT works fine under windows (where paths have spaces, etc.), and on UTF-8 files
  * Simplify `s:errors` functions
  * Support Embedded comments like for instance:

        ```
        Assert 1 == 1 " 1 must value 1
        ```

  * Ways to test buffers produced
  * Find a way to prevent the potential script scope pollution
  * Add a summary at the end of the execution


## Design Choices
  * The assertions supported by this plugin are expected to be made in a Unit Testing file, they are not to be used in regular VimL scripts as a _Design by Contract_ tool. Check my [DbC framework](http://github.com/LucHermitte/lh-vim-lib/tree/master/doc/DbC.md) in lh-vim-lib, or even Thomas Link's plugin, it is much more suited for that kind of assertions.

  * In order to be able to produce the quickfix entries, the plugin first parses the Unit Test file to complete all `:Assert` occurrences with extra information about the line number where the assertion is made. Incidentally, this permits to reduce plugin footprint: none of `:AssertXXX` commands are actual commands.

## Installation
  * Requirements: Vim 7.+, [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib) v5.1.0
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
  * Dhruva Sagar's [vim-testify](https://github.com/dhruvasagar/vim-testify)

