"=============================================================================
" File:         spec/input-mock.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/mu-template>
" Version:      0.6.0
let s:k_version = '060'
" Created:      17th Dec 2015
" Last Update:  18th Dec 2015
"------------------------------------------------------------------------
" Description:
" Mock INPUT and CONFIRM functions for vimrunner tests
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

function! INPUT(...)
  return exists('g:mocked_input') ? g:mocked_input : a:2
endfunction

function! CONFIRM(...)
  return g:mocked_confirm
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
