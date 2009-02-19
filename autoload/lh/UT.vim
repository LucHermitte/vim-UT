"=============================================================================
" $Id$
" File:         autoload/lh/UT.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://hermitte.free.fr/vim/>
" Version:      0.0.1
" Created:      11th Feb 2009
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:  Yet Another Unit Testing Framework for Vim 
" 
"------------------------------------------------------------------------
" Installation: «install details»
" History:      
" Strongly inspired by Tom Link's tAssert plugin: all its functions are
" compatible with this framework.
"
" Features:
" - Assertion failures are reported in the quickfix window
" - Assertion syntax is simple, check Tom Link's suite, it's the same
" - Supports banged :Assert! to stop processing a given test on the first error
" - One file == a suite
" - All the s:Test* functions of a suite are executed (almost) independently
"   (i.e., a critical :Assert! failure will stop the Test of the function, and
"   lh#UT will proceed to the next s:Test function
" - Lightweight and simple to use: there is only one command defined, all the
"   other definitions are kept in an autoload plugin.
" - A suite == a file
" - Several s:TestXxx() per suite, + optional s:Setup() and s:Teardown() 
" - +optional s:Setup(), s:Teardown()
" - Supports :Comments
" - s:LocalFunctions(), s:variables, and l:variables are supported
" - Takes advantage of BuildToolsWrapper's :COpen command if installed
"
" TODO:         
" - add &efm for viml errors like the one produced by :Assert 0 + [0]
" - test under windows
" - Command to exclude, or specify the tests to play => UTPlay, UTIgnore
" - simplify s:errors functions
" - merge with Tom Link tAssert plugin? (the UI is quite different)
" - :AssertEquals that shows the name of both expresions and their values as
"   well -- a correct distinction of both parameters will be tricky with
"   regexes ; using functions will loose either the name, or the value in case
"   of local/script variables use ; we need macros /à la C/...
" - Support Embedded comments like for instance: 
"   Assert 1 == 1 " 1 must value 1
" - Ways to test buffers produced
" - Count successful tests and not successful assertions
" - Shortcuts to run the Unit Tests associated to a given vim script
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" ## Functions {{{1
"------------------------------------------------------------------------
" # Debug {{{2
function! lh#UT#verbose(level)
  let s:verbose = a:level
endfunction

function! s:Verbose(expr, ...)
  let lvl = a:0>0 ? a:1 : 1
  if exists('s:verbose') && s:verbose >= lvl
    echomsg a:expr
  endif
endfunction

function! lh#UT#debug(expr)
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" # Internal functions {{{2
"------------------------------------------------------------------------
 
" Sourcing a script doesn't imply a new entry with its name in :scriptnames
" As a consequence, the easiest thing to do is to reuse the same file over and
" over in a given vim session.
" This approach should be fine as long as there are less than 26 VimL testing vim
" sessions opened simultaneously.
let s:tempfile = tempname()

let s:errors = {
      \ 'qf'         : [],
      \ 'crt_suite'  : {},
      \ 'nb_asserts' : 0,
      \ 'nb_success' : 0,
      \ 'suites'     : []
      \ }

function! s:errors.clear() dict
  let self.qf         = []
  let self.nb_asserts = 0
  let self.nb_success = 0
  let self.suites     = []
endfunction

function! s:errors.display() dict
  call add(self.qf, self.nb_success .'/'. self.nb_asserts . ' tests successfully executed.')
  let g:errors = self.qf
  cexpr self.qf

  " Open the quickfix window
  if exists(':Copen')
    " Defined in lh-BTW, make the windows as big as the number of errors, not
    " opened if there is no errors
    Copen
  else
    copen
  endif
endfunction

" Suites wrapper functions
function! s:AddTest(test_name) dict
  call add(self.tests, a:test_name)
endfunction

function! s:errors.new_suite(scriptname) dict
  let suite = {
        \ 'scriptname': a:scriptname,
        \ 'tests'     : [],
        \ 'snr'       : '',
        \ 'add_test'  : function('s:AddTest')
        \ }
  call add(self.suites, suite)
  let self.crt_suite = suite
  return suite
endfunction

function! s:errors.set_suite(suite_name) dict
  let a = s:Decode(a:suite_name)
  call s:Verbose('SUITE <- '. a.expr, 1)
  call s:Verbose('SUITE NAME: '. a:suite_name, 2)
  call self.add(a.file, a.line, 'SUITE <'. a.expr .'>')
  let self.crt_suite.name = a.expr
  let self.crt_suite.file = a.file
endfunction

function! s:errors.set_current_SNR(SNR)
  let self.crt_suite.snr = a:SNR
endfunction

function! s:errors.get_current_SNR()
  return self.crt_suite.snr
endfunction

function! s:errors.add(FILE, LINE, message) dict
  let msg = a:FILE.':'.a:LINE.':'.a:message
  call add(self.qf, msg)
endfunction

function! s:errors.add_test(test_name) dict
  call add(self.crt_suite.tests, a:test_name)
endfunction

"------------------------------------------------------------------------
function! s:Decode(expression)
  let filename = matchstr(a:expression, '^\(\\ \|\\\\\|\S\)\+')
  let expr = strpart(a:expression, strlen(filename)+1)
  let line = matchstr(expr, '^\d\+')
  " echo filename.':'.line
  let expr = strpart(expr, strlen(line)+1)
  let res = { 'file':filename, 'line':line, 'expr':expr}
  call s:Verbose('decode:'. (res.file) .':'. (res.line) .':'. (res.expr), 2)
  return res
endfunction

function! lh#UT#callback_decode(expression)
  return s:Decode(a:expression)
endfunction

"------------------------------------------------------------------------
let s:k_commands = '\%(Assert\|UTSuite\|Comment\)'
let s:k_local_evaluate = [
      \ 'command! -bang -nargs=1 Assert '.
      \ 'let s:a = lh#UT#callback_decode(<q-args>) |'.
      \ 'let s:ok = !empty(eval(s:a.expr))  |'.
      \ 'exe "UTAssert<bang> ".s:ok." ".(<f-args>)|'
      \]
let s:k_getSNR   = [
      \ 'function! s:getSNR()',
      \ '  if !exists("s:SNR")',
      \ '    let s:SNR=matchstr(expand("<sfile>"), "<SNR>\\d\\+_\\zegetSNR$")',
      \ '  endif',
      \ '  return s:SNR', 
      \ 'endfunction',
      \ 'call lh#UT#callback_set_SNR(s:getSNR())',
      \ ''
      \ ]

function! s:PrepareFile(file)
  if !filereadable(a:file)
    call s:errors.add('-', 0, a:file . " can not be read")
    return 
  endif
  let file = escape(a:file, ' \')

  let lines = readfile(a:file)
  let need_to_know_SNR = 0
  let suite = s:errors.new_suite(s:tempfile)

  let no = 0
  let last_line = len(lines)
  while no < last_line
    if lines[no] =~ '^\s*'.s:k_commands.'\>'
      let lines[no] = substitute(lines[no], '^\s*'.s:k_commands.'!\= \zs', file.' '.(no+1).' ', '')

    elseif lines[no] =~ '^\s*function!\=\s\+s:Test'
      let test_name = matchstr(lines[no], '^\s*function!\=\s\+s:\zsTest\S\{-}\ze(')
      call suite.add_test(test_name)
    elseif lines[no] =~ '^\s*function!\=\s\+s:Teardown'
      let suite.teardown = 1
    elseif lines[no] =~ '^\s*function!\=\s\+s:Setup'
      let suite.setup = 1
    endif
    if lines[no] =~ '^\s*function!\=\s\+s:'
      let need_to_know_SNR = 1
    endif
    let no += 1
  endwhile

  " Inject s:getSNR() in the script if there is a s:Function in the Test script
  if need_to_know_SNR
    call extend(lines, s:k_getSNR, 0)
    let last_line += len(s:k_getSNR)
  endif

  " Inject local evualation of expressions in the script
  " => takes care of s:variables, s:Functions(), and l:variables
  call extend(lines, s:k_local_evaluate, 0)

  call writefile(lines, s:tempfile)
  let g:lines=lines
endfunction

function! s:RunOneFile(file)
  try 
    call s:PrepareFile(a:file)
    exe 'source '.s:tempfile

    if !empty(s:errors.crt_suite.tests)
      for test in s:errors.crt_suite.tests
        call s:RunOneTest(test, a:file)
      endfor
    endif

  catch /Assert: abort/
    call s:errors.add(a:file, 
          \ matchstr(v:exception, '.*(\zs\d\+\ze)'),
          \ 'Suite <'. s:errors.crt_suite .'> execution aborted on critical assertion failure')
  catch /.*/
    let throwpoint = substitute(v:throwpoint, escape(s:tempfile, '.\'), a:file, 'g')
    let msg = throwpoint . ': '.v:exception
    call s:errors.add(a:file, 0, msg)
  finally
    " Never! the name must not be used by other Vim sessions
    " call delete(s:tempfile)
  endtry
endfunction

"------------------------------------------------------------------------
function! s:DefineCommands()
  " NB: variables are already interpreted, make it a function
  " command! -nargs=1 Assert call s:Assert(<q-args>)
  command! -bang -nargs=1 UTAssert 
        \ let s:a = s:Decode(matchstr(<q-args>, '^\d\+\s\+\zs.*'))                |
        \ let s:ok = matchstr(<q-args>, '^\d\+\ze\s\+.*')                         |
        \ let s:errors.nb_asserts += 1                                            |
        \ if ! s:ok                                                               |
        \    call s:errors.add(s:a.file, s:a.line, 'assertion failed: '.s:a.expr) |
        \    if '<bang>' == '!'                                                   |
        \       throw "Assert: abort (".s:a.line.")"                              |
        \    endif                                                                |
        \ else                                                                    |
        \    let s:errors.nb_success += 1                                         |
        \ endif

  command! -nargs=1 Comment
        \ let s:a = s:Decode(<q-args>)                                            |
        \ call s:errors.add(s:a.file, s:a.line, s:a.expr)
  command! -nargs=1 UTSuite call s:errors.set_suite(<q-args>)
endfunction

function! s:UnDefineCommands()
  delcommand Assert
  delcommand UTAssert
  command! -nargs=* UTSuite :echoerr "Use :UTRun and not :source on this script"<bar>finish
endfunction
"------------------------------------------------------------------------
" # callbacks {{{2
function! lh#UT#callback_set_SNR(SNR)
  call s:errors.set_current_SNR(a:SNR)
endfunction

function! s:RunOneTest(test_name, file)
  try
    if has_key(s:errors.crt_suite, 'setup')
      let F = function(s:errors.get_current_SNR().'Setup')
      call F()
    endif
    let F = function(s:errors.get_current_SNR().a:test_name)
    call F()
    if has_key(s:errors.crt_suite, 'teardown')
      let F = function(s:errors.get_current_SNR().'Teardown')
      call F()
    endif
  catch /Assert: abort/
    call s:errors.add(a:file, 
          \ matchstr(v:exception, '.*(\zs\d\+\ze)'),
          \ 'Test <'. a:test_name .'> execution aborted on critical assertion failure')
  catch /.*/
    let throwpoint = substitute(v:throwpoint, escape(s:tempfile, '.\'), a:file, 'g')
    let msg = throwpoint . ': '.v:exception
    call s:errors.add(a:file, 0, msg)
  finally
  endtry
endfunction

" # Main function {{{2
function! lh#UT#Run(bang,...)
  " 1- clear the errors table
  let must_keep = a:bang == "!"
  if ! must_keep
    call s:errors.clear()
  endif

  try 
    " 2- define commands
    call s:DefineCommands()

    " 3- run every test
    for file in a:000
      call s:RunOneFile(file)
    endfor
  finally
    call s:UnDefineCommands()
    call s:errors.display()
  endtry

  " 3- Open the quickfix
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
