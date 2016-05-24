"=============================================================================
" File:		autoload/should/be.vim                            {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-UT>
" Version:	1.0.1
" Created:	23rd Feb 2009
" Last Update:	24th May 2016
"------------------------------------------------------------------------
" Description:
" 	UT & tAssert API
"
"------------------------------------------------------------------------
" Installation:
" 	Drop this file into {rtp}/autoload/should
" History:
"
" TODO:		«missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" ## Functions {{{1
" # Debug {{{2
function! should#be#verbose(level)
  let s:verbose = a:level
endfunction

function! s:Verbose(expr)
  if exists('s:verbose') && s:verbose
    echomsg a:expr
  endif
endfunction

function! should#be#debug(expr)
  return eval(a:expr)
endfunction


" # Convinience functions for tAssert/UT {{{2
function! should#be#list(var)
  return type(a:var) == type([])
endfunction
function! should#be#number(var) abort
  return type(a:var) == type(42)
endfunction
function! should#be#string(var)
  return type(a:var) == type('')
endfunction
function! should#be#dict(var)
  return type(a:var) == type({})
endfunction
if has('float')
  function! should#be#float(var)
    return type(a:var) == type(0.1)
  endfunction
endif
function! should#be#funcref(var)
  return type(a:var) == type(function('exists'))
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
