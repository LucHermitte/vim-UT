"=============================================================================
" $Id$
" File:		tests/lh/UT-fixtures.vim                                  {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	0.0.1
" Created:	11th Feb 2009
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	UnitTests for the UT plugin. 
" - Test fixtures
" 
"------------------------------------------------------------------------
" Installation:	«install details»
" History:	«history»
" TODO:		«missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
UTSuite [lh#UT] Testing fixtures

let s:v1 = 0
let s:v2 = 0

function! s:Setup()
  Assert! exists('s:v1')
  Assert! exists('s:v2')
  let s:v1 += 1
  let s:v2 += 1
endfunction

function! s:Teardown()
  let s:v1 = 0
endfunction

function! s:TestSetup()
  Comment First test where s:v1 and g:v2 are set to 1
  " Assert0 s:v1 == 1
  Assert s:v1 == 1
  Assert s:v2 == 1
endfunction

function! s:TestTeardown()
  Comment Second test where only s:v1 is incremented, while g:v2 is set to 1
  Assert s:v1 == 1
  Assert s:v2 == 2
endfunction

" UTPlay TestTeardown
UTIgnore TestTeardown

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
