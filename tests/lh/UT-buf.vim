"=============================================================================
" File:         tests/lh/UT-buf.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-UT>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-UT/blob/master/License.md>
" Version:      2.0.0.
let s:k_version = '200'
" Created:      06th May 2020
" Last Update:  08th May 2020
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
function! s:Test_SetBuffer_EOF()
  silent! call lh#window#create_window_with('new') " work around possible E36
  file toto.test
  try
    SetBufferContent << trim EOF
    1
    2
    3
    EOF
    call lh#UT#assert_buffer_match('', 37, ['1', '2', '3'])
  finally
    silent! bw!
  endtry
endfunction

function! s:Test_SetBuffer_file()
  silent! call lh#window#create_window_with('new') " work around possible E36
  file toto.test
  try
    SetBufferContent tests/lh/1-2-3.txt
    call lh#UT#assert_buffer_match('', 49, ['1', '2', '3'])
  finally
    silent! bw!
  endtry
endfunction

function! s:Test_AssertBuffer_EOF()
  silent! call lh#window#create_window_with('new') " work around possible E36
  file toto.test
  try
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
  finally
    silent! bw!
  endtry
endfunction

function! s:Test_AssertBuffer_file()
  silent! call lh#window#create_window_with('new') " work around possible E36
  file toto.test
  try
    SetBufferContent << trim EOF
    1
    2
    3
    EOF
    AssertBufferMatch tests/lh/1-2-3.txt
  finally
    silent! bw!
  endtry
endfunction

function! s:Test_AssertBuffer_file_file()
  silent! call lh#window#create_window_with('new') " work around possible E36
  file toto.test
  try
    SetBufferContent tests/lh/1-2-3.txt
    AssertBufferMatch tests/lh/1-2-3.txt
  finally
    silent! bw!
  endtry
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
