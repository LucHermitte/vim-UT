"=============================================================================
" File:         tests/lh/UT-buf.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-UT>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-UT/blob/master/License.md>
" Version:      2.0.0.
let s:k_version = '200'
" Created:      06th May 2020
" Last Update:  14th May 2020
"------------------------------------------------------------------------
" Description:
"       Unit Test for UT's :SetBufferContent & :AssertBufferMatch
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

UTSuite [lh#UT] Testing Buffer testing features

" runtime autoload/lh/UT.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:BeforeAll() abort
  silent! call lh#window#create_window_with('new') " work around possible E36
  file toto.test
endfunction

function! s:AfterAll() abort
  silent! bw!
endfunction

"------------------------------------------------------------------------
function! s:Test_SetBuffer_EOF()
  SetBufferContent << trim EOF
  1
  2

  3
  EOF
  call lh#UT#assert_buffer_match('', 46, ['1', '2', '', '3'])
endfunction

function! s:Test_SetBuffer_file()
  SetBufferContent tests/lh/1-2-3.txt
  call lh#UT#assert_buffer_match('', 49, ['1', '2', '3'])
endfunction

function! s:Test_AssertBuffer_EOF()
  SetBufferContent << trim EOF
  1
  2
  3
  EOF
  AssertBufferMatch << trim EOF
  1
  2
  3
  EOF
endfunction

function! s:Test_AssertBuffer_file()
  SetBufferContent << trim EOF
  1
  2
  3
  EOF
  AssertBufferMatch tests/lh/1-2-3.txt
endfunction

function! s:Test_AssertBuffer_file_file()
  SetBufferContent tests/lh/1-2-3.txt
  AssertBufferMatch tests/lh/1-2-3.txt
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
