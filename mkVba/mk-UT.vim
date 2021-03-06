"=============================================================================
" File:		mk-UT.vim
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-UT>
" Version:	2.0.6
let s:version = '2.0.6'
" Created:	19th Feb 2009
" Last Update:	19th Mar 2021
"------------------------------------------------------------------------
cd <sfile>:p:h
try
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '21,$MkVimball! UT-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
License.md
README.md
VimFlavor
addon-info.json
autoload/lh/UT.vim
autoload/should.vim
autoload/should/be.vim
doc/UT.txt
doc/rspec-integration.md
ftplugin/vim/vim_UT.vim
mkVba/mk-UT.vim
plugin/UT.vim
tests/lh/UT-fixtures.vim
tests/lh/UT.vim
tests/lh/assert.vim
