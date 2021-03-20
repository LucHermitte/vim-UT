"=============================================================================
" File:         spec/input-mock.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/mu-template>
" Version:      2.0.6.
let s:k_version = '206'
" Created:      17th Dec 2015
" Last Update:  20th Mar 2021
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

" Unfortunately, for some reason I cannot save the original version in
" funcref() in order to decide wich to call...
function! lh#ui#confirm(...)
  if  type(g:mocked_confirm) == type([])
    return remove(g:mocked_confirm, 0)
  else
    return g:mocked_confirm
  endif
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
