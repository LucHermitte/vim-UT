"=============================================================================
" File:         tests/lh/README.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-UT>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-UT/blob/master/License.md>
" Version:      2.0.0.
let s:k_version = '200'
" Created:      13th May 2020
" Last Update:  13th May 2020
"------------------------------------------------------------------------
" Description:
"       Tests from README.md
" }}}1
"=============================================================================

UTSuite [lh#UT] Demonstrate assertions in README

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:Bar(v) abort
  return a:v /2
endfunction
let g:var = 5
let s:foo = -1

Assert 1 > 2
Assert 1 > 0
Assert s:foo > s:Bar(g:var + 28) / strlen("foobar")

debug AssertTxt (s:foo > s:Bar(g:var+28)
      \, s:foo." isn't bigger than s:Bar(".g:var."+28)")
AssertEquals!('a', 'a')
AssertDiffers('a', 'a')
let dict = {}
AssertIs(dict, dict)
AssertIsNot(dict, dict)
AssertMatch('abc', 'a')
AssertRelation(1, '<', 2)
AssertThrows 0 + [0]

"------------------------------------------------------------------------
function! SomeFunction() abort
  return 42
endfunction

function s:Test1()
  let var = SomeFunction()
  Assert! type(var) == type(0)
  Assert var < 42
  Assert! var > 0

  " Some other code that won't be executed if the previous assertion failed
  " /*the wiki does not recognizes vim comments*/
  let i = var / 42.0
  Comment "This comment may never be displayed if {g:var} is negative or not a number"
endfunction

"------------------------------------------------------------------------

function! s:Test_diff() abort
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
    4
    3
    EOF
  finally
    silent! bw!
  endtry
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
