"=============================================================================
" $Id$
" File:		mk-UT.vim
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	0.0.1
let s:version = '0.0.1'
" Created:	19th Feb 2009
" Last Update:	$Date$
"------------------------------------------------------------------------
cd <sfile>:p:h
try 
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '22,$MkVimball! UT-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
autoload/lh/UT.vim
mkVba/mk-UT.vim
plugin/UT.vim
tests/lh/UT-fixtures.vim
tests/lh/UT.vim
UT.README
