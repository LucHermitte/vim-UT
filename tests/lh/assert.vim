"=============================================================================
" File:		assert.vim                                        {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-UT>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	0.1.1
" Created:	16th Feb 2009
" Last Update:	18th Apr 2015
"------------------------------------------------------------------------
" Description:	UnitTests for the UT plugin.
" - Tests global assertions
" - Tests assertions definied in tests (functions s:Test)
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
UTSuite [lh#UT] Testing global and local assertions

" runtime autoload/lh/UT.vim

Assert 1 == 1
Assert 1 != 42
Assert 1 < 20
Assert 1 > 20

let st = "string"
Assert st =~ 'str'
Assert st !~ 'str'
Assert st == 'str'
Assert st != 'str'
Assert st == 0
" Assert 0 + [0]

function! s:One()
  return 1
endfunction
Assert s:One() == 1

"------------------------------------------------------------------------
function! s:TestOK()
  Comment 'TestOK'
  Assert! 1 == 1
  Assert 1 == 1
  Assert repeat('1', 5) == '11111'
  Assert! repeat('1', 5) == '11111'

  AssertEquals('a', 'a')
  AssertDiffers('a', 'b')
  let dict = {}
  AssertIs(dict, dict)
  AssertMatch('abc', 'a')
  AssertRelation(1, '<', 2)
endfunction

"------------------------------------------------------------------------
function! s:TestCriticalNOK()
  Comment 'TestCriticalNOK'
  Assert! 1 == 0
  Assert repeat('1', 5) == '1111'
endfunction

"------------------------------------------------------------------------
function! s:TestNOK()
  Comment 'TestNOK'
  Assert 0 == 1
  Assert repeat('1', 5) == '1111'

  AssertEquals('a', 'b')
  AssertDiffers('a', 'a')
  AssertIs({}, {})
  AssertMatches('a', 'abc')
  AssertRelation(3, '<', 2)
endfunction

function! s:Foo()
endfunction
"------------------------------------------------------------------------
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
