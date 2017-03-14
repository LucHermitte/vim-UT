"=============================================================================
" File:         spec/input-mock.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/mu-template>
" Version:      1.0.6.
let s:k_version = '106'
" Created:      17th Dec 2015
" Last Update:  14th Mar 2017
"------------------------------------------------------------------------
" Description:
" Mock lh#ui#input and lh#ui#confirm functions for vimrunner tests
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

" First load the true definitions in order to overwrite them
runtime autoload/lh/ui.vim

function! lh#ui#input(...)
  return exists('g:mocked_input') ? g:mocked_input : a:2
endfunction

function! lh#ui#confirm(...)
  return g:mocked_confirm
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
