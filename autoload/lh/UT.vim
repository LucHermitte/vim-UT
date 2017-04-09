"=============================================================================
" File:         autoload/lh/UT.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-UT>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-UT/License.md>
" Version:      1.0.8
" Created:      11th Feb 2009
" Last Update:  09th Apr 2017
"------------------------------------------------------------------------
" Description:  Yet Another Unit Testing Framework for Vim
"
"------------------------------------------------------------------------
" Installation:
" 	Drop this file into {rtp}/autoload/lh/
" History:
" 	Strongly inspired by Tom Link's tAssert plugin: all its functions are
" 	compatible with this framework.
" 	v1.0.8: Accept space before function brackets
" 	v1.0.5: Short-circuit `Toggle PluginAssertmode`
" 	v1.0.4: Throw exceptions on lh-vim-lib assertion failures in AssertThrow
" 	v1.0.3: Support "debug" before `AssertEq` & co
" 	v1.0.2: Extract s:Setup() call from try..finally block
" 	v1.0.1: Missing aborts
" 	        Highlight qf results
" 	        Set the test as failed when exceptions are caught
" 	        Always execute `Teardown()`
"               Take into account the offset introduced by lines injected at
"               the top of the file
" 	v1.0.0: UTRun no longer looks into &rtp
" 	v0.6.1: Fix `UTRun tests/lh/*.vim`
" 	v0.4.0: New Assert function AssertThrow
" 	        'magic' neutral
" 	v0.2.0: Better integration with vimrunner+rspec
" 	        lh#run#check() will help
" 	v0.1.4: Verbosity in qf window can be controled with lh#UT#print_test_names()
" 	v0.1.3: Test name automatically deduced when :UTSuite isn't called.
" 	v0.1.2: Exception callstack decoded (requires lh-vim-lib 3.3.11)
" 	        AssertIsNot added
" 	        lh#UT#run() returns a list that can be exploited from
" 	        RSpec+vimrunner
" 	v0.1.1: New assert commands: AssertEquals, AssertDiff, AssertIs,
" 	        AssertMatches, AssertRelation
" 	v0.1.0: New assertion command :AssertTxt(expr, message) that let choose
" 	        the assertion failure message.
" 	v0.0.7: bug fix to support "UTRun %", whatever the current path & &rtp
" 	        are.
" 	v0.0.6: exception callstack displayed
" 	v0.0.5: displays exceptions thrown in :Assert.
" 	v0.0.4: patch from Motoya Kurotsu
"
" Features:
" - Assertion failures are reported in the quickfix window
" - Assertion syntax is simple, check Tom Link's suite, it's the same
" - Supports banged :Assert! to stop processing a given test on failed
"   assertions
" - All the s:Test* functions of a suite are executed (almost) independently
"   (i.e., a critical :Assert! failure will stop the Test of the function, and
"   lh#UT will proceed to the next s:Test function
" - Lightweight and simple to use: there is only one command defined, all the
"   other definitions are kept in an autoload plugin.
" - A suite == a file
" - Several s:TestXxx() per suite
" - +optional s:Setup(), s:Teardown()
" - Supports :Comment's ; :Comment takes an expression to evaluate
" - s:LocalFunctions(), s:variables, and l:variables are supported
" - Takes advantage of BuildToolsWrapper's :Copen command if installed
" - Count successful tests (and not successful assertions)
" - Short-cuts to run the Unit Tests associated to a given vim script
"   Relies on: Let-Modeline/local_vimrc/Project to set g:UTfiles (space
"   separated list of glob-able paths), and on lh-vim-lib#path
" - Command to exclude, or specify the tests to play => UTPlay, UTIgnore
" - Option g:UT_print_test to display, on assertion failure, the current test
"   name with the assertion failed.
"
" TODO:
" - Test in UTF-8 (because of <SNR>_ injection)
" - test under windows (where paths have spaces, etc)
" - What about s:/SNR pollution ? The tmpfile is reused, and there is no
"   guaranty a script will clean its own place
" - add &efm for viml errors like the one produced by :Assert 0 + [0]
" - simplify s:errors functions
" - merge with Tom Link tAssert plugin? (the UI is quite different)
" - Support Embedded comments like for instance:
"   Assert 1 == 1 " 1 must value 1
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

let s:print_test_names = 0
function! lh#UT#print_test_names()
  let s:print_test_names = 1
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

"------------------------------------------------------------------------
" Errors {{{3
" s:errors {{{4
let s:errors = {
      \ 'qf'                    : [],
      \ 'crt_suite'             : {},
      \ 'nb_asserts'            : 0,
      \ 'nb_successful_asserts' : 0,
      \ 'nb_success'            : 0,
      \ 'suites'                : []
      \ }

" Function: s:errors.clear() dict {{{4
function! s:errors.clear() dict abort
  let self.qf                    = []
  let self.nb_asserts            = 0
  let self.nb_successful_asserts = 0
  let self.nb_success            = 0
  let self.nb_tests              = 0
  let self.suites                = []
  let self.crt_suite             = {}
endfunction

" Function: s:errors.display() dict {{{4
function! s:errors.display() dict abort
  " let g:errors = self.qf
  silent! cexpr self.qf

  " Open the quickfix window
  if exists(':Copen')
    " Defined in lh-BTW, make the windows as big as the number of errors, not
    " opened if there is no error
    Copen
  else
    silent! copen
  endif
endfunction

" Function: s:errors.set_current_SNR(SNR) {{{4
function! s:errors.set_current_SNR(SNR) abort
  let self.crt_suite.snr = a:SNR
endfunction

" Function: s:errors.get_current_SNR() {{{4
function! s:errors.get_current_SNR() abort
  return self.crt_suite.snr
endfunction

" Function: s:errors.add(FILE, LINE, message) dict {{{4
function! s:errors.add(FILE, LINE, message) dict abort
  let msg = a:FILE.':'.a:LINE.':'
  if lh#option#get('UT_print_test', 0, 'g') && has_key(s:errors, 'crt_test')
    let msg .= '['. s:errors.crt_test.name .'] '
  endif
  let message = split(a:message, "\n")
  let msg.= message[0]
  call add(self.qf, msg)
  let self.qf += message[1:]
endfunction

" Function: s:errors.add_test(test_name) dict {{{4
function! s:errors.add_test(test_name) dict abort
  call self.add_test(a:test_name)
endfunction

" Function: s:errors.set_test_failed() dict {{{4
function! s:errors.set_test_failed() dict abort
  if has_key(self, 'crt_test')
    let self.crt_test.failed = 1
  endif
endfunction

" Function: lh#UT#_callstack(throwpoint) {{{3
function! lh#UT#_callstack(throwpoint) abort
  let msg = ''
  " Ignore functions from this script
  let callstack = filter(lh#exception#callstack(a:throwpoint), 'v:val.script !~ ".*autoload.lh.UT.vim"')
  for func in callstack
    if s:tempfile == func.script
      let func.script = substitute(func.script, escape(s:tempfile, '.\'), s:errors.crt_suite.file, 'g')
      let func.pos    = func.pos - s:errors.offset
    endif
    " call s:errors.add(func.script, func.pos, '  called from '.(func.fname).'['.(func.offset).']')
    let msg .= "\n".(func.script).':'.(func.pos).': called from '.(func.fname).'['.(func.offset).']'
  endfor
  return msg
endfunction

" Function: lh#UT#_highlight_qf() {{{3
function! lh#UT#_highlight_qf() abort
  if &ft == 'qf' && has('syntax')
    syntax region UTConclusion start="SUITE" end="tests successfully executed." contains=UTCount contained
    syntax region UTCount start="\d\+/\d\+" end="tests" contains=UTFail,UTSuccess contained
    syntax match UTFail "\v(\d+)/\d+"
    syntax match UTSuccess "\v(\d+)/\1"

    highlight link UTSuccess Type
    highlight link UTFail    Error
  endif
endfunction

augroup UT_hl_qf
  au!
  au FileType qf call lh#UT#_highlight_qf()
augroup END

"------------------------------------------------------------------------
" Tests wrapper function {{{3

" Function: s:RunOneTest(file) dict abort {{{4
function! s:RunOneTest(file) dict abort
  try
    let s:errors.crt_test = self
    if has_key(s:errors.crt_suite, 'setup')
      let F = function(s:errors.get_current_SNR().'Setup')
      call F()
    endif
    try
      let F = function(s:errors.get_current_SNR(). self.name)
      call F()
    finally
      if has_key(s:errors.crt_suite, 'teardown')
        let F = function(s:errors.get_current_SNR().'Teardown')
        call F()
      endif
    endtry
  catch /Assert: abort/
    call s:errors.add(a:file,
          \ matchstr(v:exception, '.*(\zs\d\+\ze)'),
          \ 'Test <'. self.name .'> execution aborted on critical assertion failure')
  catch /.*/
    let throwpoint = substitute(v:throwpoint, escape(s:tempfile, '.\'), a:file, 'g')
    let msg = throwpoint . ': '.v:exception
    let msg .= lh#UT#_callstack(v:throwpoint)
    call s:errors.add(a:file, 0, msg)
    call s:errors.set_test_failed()
  finally
    unlet s:errors.crt_test
    if s:print_test_names
      call s:errors.add(a:file, 0, "Test <".(self.name)."> executed ". (self.failed ? 'but failed' : 'with success') )
    endif
  endtry
endfunction

" Function: s:AddTest(test_name) dict {{{4
function! s:AddTest(test_name) dict abort
  let test = {
        \ 'name'   : a:test_name,
        \ 'run'    : function('s:RunOneTest'),
        \ 'failed' : 0
        \ }
  call add(self.tests, test)
endfunction

"------------------------------------------------------------------------
" Suites wrapper functions {{{3

" Function: s:ConcludeSuite() dict {{{4
function! s:ConcludeSuite() dict abort
  let name = self.name
  call s:errors.add(self.file, 0,  'SUITE<'. name .'> '. (s:errors.nb_success) .'/'. (s:errors.nb_tests) . ' tests successfully executed.')
  " call add(s:errors.qf, 'SUITE<'. self.name.'> '. s:rrors.nb_success .'/'. s:errors.nb_tests . ' tests successfully executed.')
  return (s:errors.nb_tests) - (s:errors.nb_success)
endfunction

" Function: s:PlayTests(...) dict {{{4
function! s:PlayTests(...) dict abort
  call s:Verbose('Execute tests: '.join(a:000, ', '))
  call filter(self.tests, 'index(a:000, v:val.name) >= 0')
  call s:Verbose('Keeping tests: '.join(self.tests, ', '))
endfunction

" Function: s:IgnoreTests(...) dict {{{4
function! s:IgnoreTests(...) dict abort
  call s:Verbose('Ignoring tests: '.join(a:000, ', '))
  call filter(self.tests, 'index(a:000, v:val.name) < 0')
  call s:Verbose('Keeping tests: '.join(self.tests, ', '))
endfunction

" Function: s:errors.new_suite(file) dict {{{4
function! s:errors.new_suite(file) dict abort
  let suite = {
        \ 'scriptname'      : s:tempfile,
        \ 'file'            : a:file,
        \ 'tests'           : [],
        \ 'snr'             : '',
        \ 'add_test'        : function('s:AddTest'),
        \ 'conclude'        : function('s:ConcludeSuite'),
        \ 'play'            : function('s:PlayTests'),
        \ 'ignore'          : function('s:IgnoreTests'),
        \ 'nb_tests_failed' : 0,
        \ 'offset'          : 0
        \ }
  " Default name, in case UTSuite is not called
  let suite.name = fnamemodify(suite.file, ':t:r')

  call add(self.suites, suite)
  let self.crt_suite = suite
  return suite
endfunction

" Function: s:errors.set_suite(suite_name) dict {{{4
function! s:errors.set_suite(suite_name) dict abort
  let a = s:Decode(a:suite_name)
  call s:Verbose('SUITE <- '. a.expr, 1)
  call s:Verbose('SUITE NAME: '. a:suite_name, 2)
  " call self.add(a.file, a.line, 'SUITE <'. a.expr .'>')
  call self.add(a.file,0, 'SUITE <'. a.expr .'>')
  let self.crt_suite.name = a.expr
  " let self.crt_suite.file = a.file
endfunction

"------------------------------------------------------------------------
" Assert & decode {{{3
" Function: s:Decode(expression) {{{4
function! s:Decode(expression) abort
  let filename = s:errors.crt_suite.file
  let expr = a:expression
  let line = matchstr(expr, '^\d\+')
  " echo filename.':'.line
  let expr = strpart(expr, strlen(line)+1)
  let res = { 'file':filename, 'line':line, 'expr':expr}
  call s:Verbose('decode:'. (res.file) .':'. (res.line) .':'. (res.expr), 2)
  return res
endfunction

" Function: lh#UT#callback_decode(expression) {{{4
function! lh#UT#callback_decode(expression) abort
  return s:Decode(a:expression)
endfunction

" Function: lh#UT#assert_txt(bang, line, expr, msg) abort {{{4
function! lh#UT#assert_txt(bang, line, expr, msg) abort
  let filename = s:errors.crt_suite.file
  let s:a = { 'file':filename, 'line':a:line, 'expr':a:expr, 'msg':a:msg}
  try
    let s:ok = !empty(eval(s:a.expr))
    exe "UTAssert".a:bang." ".s:ok." ".a:line." ".a:msg
  catch /.*/
    let s:ok = 0
    let msg = (a:msg." -- exception thrown: ".v:exception." at: ".v:throwpoint)
    let msg .= lh#UT#_callstack(v:throwpoint)
    exe "UTAssert".a:bang." ".s:ok." ".a:line." ".msg
  endtry
endfunction

" Function: lh#UT#assert_equals(bang, line, lhs, rhs) {{{4
function! lh#UT#assert_equals(bang, line, lhs, rhs) abort
  return lh#UT#assert_txt(a:bang, a:line, a:lhs == a:rhs,
        \ string(a:lhs) . ' is not equal to ' . string(a:rhs))
endfunction

" Function: lh#UT#assert_differs(bang, line, lhs, rhs) {{{4
function! lh#UT#assert_differs(bang, line, lhs, rhs) abort
  return lh#UT#assert_txt(a:bang, a:line, a:lhs != a:rhs,
        \ string(a:lhs) . ' is not different from ' . string(a:rhs))
endfunction

" Function: lh#UT#assert_is(bang, line, lhs, rhs) {{{4
function! lh#UT#assert_is(bang, line, lhs, rhs) abort
  return lh#UT#assert_txt(a:bang, a:line, a:lhs is a:rhs,
        \ string(a:lhs) . ' is not identical to ' . string(a:rhs))
endfunction

" Function: lh#UT#assert_is_not(bang, line, lhs, rhs) {{{4
function! lh#UT#assert_is_not(bang, line, lhs, rhs) abort
  return lh#UT#assert_txt(a:bang, a:line, ! (a:lhs is a:rhs),
        \ string(a:lhs) . ' is not identical to ' . string(a:rhs))
endfunction

" Function: lh#UT#assert_matches(bang, line, lhs, rhs) {{{4
function! lh#UT#assert_matches(bang, line, lhs, rhs) abort
  return lh#UT#assert_txt(a:bang, a:line, a:lhs =~ a:rhs,
        \ string(a:lhs) . ' does not match ' . string(a:rhs))
endfunction

" Function: lh#UT#assert_relation(bang, line, lhs, rel, rhs) {{{4
function! lh#UT#assert_relation(bang, line, lhs, rel, rhs) abort
  let expr = string(a:lhs) . ' ' . a:rel . ' ' .string(a:rhs)
  let ok = eval(expr)
  return lh#UT#assert_txt(a:bang, a:line, ok, expr)
endfunction

"------------------------------------------------------------------------
" Function: lh#UT#assert_throws(bang, line, lhs) {{{4
function! lh#UT#assert_throws(bang, line, lhs) abort
  try
    " We should normally rely on lh#assert#mode(), but as it uses
    " `Toggle PluginAssertmode`, let's take a shortcut.
    let cleanup = lh#on#exit()
          \.restore('g:lh#assert#_mode')
    let g:lh#assert#_mode = 'stop'
    call eval(a:lhs)
    return lh#UT#assert_txt(a:bang, a:line, 0,
        \ a:lhs . ' does not throw')
  catch /.*/
    " nominal case...
  finally
    call cleanup.finalize()
  endtry
endfunction

" Transform file {{{3
" constants {{{4
let s:k_commands = '%(Assert|UTSuite|Comment)'
let s:k_local_evaluate = [
      \ 'command! -bang -nargs=1 Assert '.
      \ 'let s:a = lh#UT#callback_decode(<q-args>)                                                                    |'.
      \ 'try                                                                                                          |'.
      \ '    let s:ok = !empty(eval(s:a.expr))                                                                        |'.
      \ '    exe "UTAssert<bang> ".s:ok." ".(<f-args>)                                                                |'.
      \ 'catch /.*/                                                                                                   |'.
      \ '    let s:ok = 0                                                                                             |'.
      \ '    let msg  = " -- exception thrown: ".v:exception." at: ".v:throwpoint                                     |'.
      \ '    let msg .= lh#UT#_callstack(v:throwpoint)                                                                |'.
      \ '    exe "UTAssert<bang> ".s:ok." ".(<f-args>.msg)                                                            |'.
      \ 'endtry                                                                                                       |'
      \]
      " \ '    let callstack = lh#exception#callstack(v:throwpoint)                                                |'.
      " \ '        call s:errors.add(func.script, func.pos, "  called from ".(func.fname)."[".(func.offset)."]")   |'.
" let s:k_local_evaluate = [
      " \ 'command! -bang -nargs=1 Assert '.
      " \ 'let s:a = lh#UT#callback_decode(<q-args>) |'.
      " \ 'let s:ok = !empty(eval(s:a.expr))  |'.
      " \ 'exe "UTAssert<bang> ".s:ok." ".(<f-args>)|'
      " \]
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

" Function: s:PrepareFile(file) {{{4
function! s:PrepareFile(file) abort
  if !filereadable(a:file)
    call s:errors.add('-', 0, a:file . " can not be read")
    return
  endif
  let file = escape(a:file, ' \')

  silent! let lines = readfile(a:file)
  let need_to_know_SNR = 0
  let suite = s:errors.new_suite(a:file)

  let isk = &isk
  set isk&vim
  try
    let no = 0
    let last_line = len(lines)
    while no < last_line
      if lines[no] =~ '\v^\s*:=%(debug\s+)=AssertTxt>'
        let lines[no] = substitute(lines[no], '^\v\s*:=%(debug\s+)=\zsAssertTxt\s*(!=)\s*\(', 'call lh#UT#assert_txt("\1", '.(no+1).',', '')

      elseif lines[no] =~ '\v^\s*:=%(debug\s+)=AssertEq%[uals]>'
        let lines[no] = substitute(lines[no], '\v^\s*:=%(debug\s+)=\zsAssertEq%[uals]\s*(!=)\s*\(', 'call lh#UT#assert_equals("\1", '.(no+1).',', '')

      " elseif lines[no] =~ '\v^\s*:=%(debug\s+)=Assert>'
        " let lines[no] = substitute(lines[no], '^\v\s*:=%(debug\s+)=\zsAssert\s*(!=)\s*(.*)', 'call lh#UT#assert_txt("\1", '.(no+1).', \2, string(\2))', '')

      elseif lines[no] =~ '^\v\s*:=%(debug\s+)=AssertDiff%[ers]>'
        let lines[no] = substitute(lines[no], '\v^\s*:=%(debug\s+)=\zsAssertDiff%[ers]\s*(!=)\s*\(', 'call lh#UT#assert_differs("\1", '.(no+1).',', '')

      elseif lines[no] =~ '^\v\s*:=%(debug\s+)=AssertIs>'
        let lines[no] = substitute(lines[no], '^\v\s*:=%(debug\s+)=\zsAssertIs\s*(!=)\s*\(', 'call lh#UT#assert_is("\1", '.(no+1).',', '')

      elseif lines[no] =~ '\v^\s*:=%(debug\s+)=AssertIsNot>'
        let lines[no] = substitute(lines[no], '\v^\s*:=%(debug\s+)=\zsAssertIsNot\s*(!=)\s*\(', 'call lh#UT#assert_is_not("\1", '.(no+1).',', '')

      elseif lines[no] =~ '\v^\s*:=%(debug\s+)=AssertMatch%[es]>'
        let lines[no] = substitute(lines[no], '\v^\s*:=%(debug\s+)=\zsAssertMatch%[es]\s*(!=)\s*\(', 'call lh#UT#assert_matches("\1", '.(no+1).',', '')

      elseif lines[no] =~ '\v^\s*:=%(debug\s+)=AssertRel%[ation]>'
        let lines[no] = substitute(lines[no], '\v^\s*:=%(debug\s+)=\zsAssertRel%[ation]\s*(!=)\s*\(', 'call lh#UT#assert_relation("\1", '.(no+1).',', '')

      elseif lines[no] =~ '\v^\s*:=%(debug\s+)=AssertTh%[rows]>'
        " TODO: stringify param 1
        let lines[no] = substitute(lines[no], '\v^\s*:=%(debug\s+)=\zsAssertTh%[rows]\s*(!=)\s*(.*)', 'call lh#UT#assert_throws("\1", '.(no+1).', "\2")', '')

      elseif lines[no] =~ '\v^\s*:='.s:k_commands.'>'
        let lines[no] = substitute(lines[no], '\v^\s*:='.s:k_commands.'!= \zs', (no+1).' ', '')

      elseif lines[no] =~ '\v^\s*:=function!=\s+s:Test'
        let test_name = matchstr(lines[no], '\v^\s*:=function!=\s+s:\zsTest\S{-}\ze\s*\(')
        call suite.add_test(test_name)
      elseif lines[no] =~ '\v^\s*:=function!=\s+s:Teardown'
        let suite.teardown = 1
      elseif lines[no] =~ '\v^\s*:=function!=\s+s:Setup'
        let suite.setup = 1
      endif
      if lines[no] =~ '\v^\s*:=function!=\s+s:'
        let need_to_know_SNR = 1
      endif
      let no += 1
    endwhile

    " Inject s:getSNR() in the script if there is a s:Function in the Test script
    let s:errors.offset = 0
    if need_to_know_SNR
      call extend(lines, s:k_getSNR, 0)
      let s:errors.offset += len(s:k_getSNR)
    endif

    " Inject local evualation of expressions in the script
    " => takes care of s:variables, s:Functions(), and l:variables
    call extend(lines, s:k_local_evaluate, 0)
    let s:errors.offset += len(s:k_local_evaluate)
  finally
    let &isk=isk
  endtry

  silent call writefile(lines, suite.scriptname)
  " let g:lines=lines
endfunction

" Function: s:RunOneFile(file) {{{4
function! s:RunOneFile(file) abort
  try
    silent call s:PrepareFile(a:file)
    let g:lh#UT#crt_file = a:file
    silent exe 'source '.s:tempfile

    let s:errors.nb_tests = len(s:errors.crt_suite.tests)
    let s:errors.nb_success = 0 " Motoya Kurotsu's patch
    if !empty(s:errors.crt_suite.tests)
      call s:Verbose('Executing tests: '.join(s:errors.crt_suite.tests, ', '))
      for test in s:errors.crt_suite.tests
        call test.run(a:file)
        let s:errors.nb_success += 1 - test.failed
      endfor
    endif

  catch /Assert: abort/
    call s:errors.add(a:file,
          \ matchstr(v:exception, '.*(\zs\d\+\ze)'),
          \ 'Suite <'. s:errors.crt_suite .'> execution aborted on critical assertion failure')
  catch /.*/
    let throwpoint = substitute(v:throwpoint, escape(s:tempfile, '.\'), a:file, 'g')
    let msg = ': '.v:exception.' @ ' . throwpoint
    let msg .= lh#UT#_callstack(v:throwpoint)
    call s:errors.add(a:file, 0, msg)
  finally
    return s:errors.crt_suite.conclude()
    " Never! the name must not be used by other Vim sessions
    " call delete(s:tempfile)
  endtry
endfunction

"------------------------------------------------------------------------
"{{{3
" Function: s:StripResultAndDecode(expr) {{{4
function! s:StripResultAndDecode(expr) abort
  " Function needed because of an odd degenerescence of vim: commands
  " eventually loose their '\'
  return s:Decode(matchstr(a:expr, '^\d\+\s\+\zs.*'))
endfunction

" Function: s:GetResult(expr) {{{4
function! s:GetResult(expr) abort
  " Function needed because of an odd degenerescence of vim: commands
  " eventually loose their '\'
  return matchstr(a:expr, '^\d\+\ze\s\+.*')
endfunction

" Function: s:DefineCommands() {{{4
function! s:DefineCommands() abort
  " NB: variables are already interpreted, make it a function
  " command! -nargs=1 Assert call s:Assert(<q-args>)
  command! -bang -nargs=1 UTAssert
        \ let s:a = s:StripResultAndDecode(<q-args>)                              |
        \ let s:ok = s:GetResult(<q-args>)                                        |
        \ let s:errors.nb_asserts += 1                                            |
        \ if ! s:ok                                                               |
        \    call s:errors.set_test_failed()                                      |
        \    call s:errors.add(s:a.file, s:a.line, 'assertion failed: '.s:a.expr) |
        \    if '<bang>' == '!'                                                   |
        \       throw "Assert: abort (".s:a.line.")"                              |
        \    endif                                                                |
        \ else                                                                    |
        \    let s:errors.nb_successful_asserts += 1                              |
        \ endif

  command! -nargs=1 Comment
        \ let s:a = s:Decode(<q-args>)                                            |
        \ call s:errors.add(s:a.file, s:a.line, eval(s:a.expr))
  command! -nargs=1 UTSuite call s:errors.set_suite(<q-args>)

  command! -nargs=+ UTPlay   call s:errors.crt_suite.play(<f-args>)
  command! -nargs=+ UTIgnore call s:errors.crt_suite.ignore(<f-args>)
endfunction

" Function: s:UnDefineCommands() {{{4
function! s:UnDefineCommands() abort
  silent! delcommand Assert
  silent! delcommand UTAssert
  silent! command! -nargs=* UTSuite :echoerr "Use :UTRun and not :source on this script"<bar>finish
  silent! delcommand UTPlay
  silent! delcommand UTIgnore
endfunction
"------------------------------------------------------------------------
" # callbacks {{{2
function! lh#UT#callback_set_SNR(SNR) abort
  call s:errors.set_current_SNR(a:SNR)
endfunction

" # Main function {{{2
function! lh#UT#run(bang,...) abort
  " 1- clear the errors table?
  let must_keep = a:bang == "!"

  " 2- Call the internal checking function
  call call('lh#UT#check', [must_keep]+a:000) " cannot fail

  " 3- Open the quickfix
  call s:errors.display()
endfunction

" Function: lh#UT#check([testnames...]) {{{2
" @throw None
function! lh#UT#check(must_keep, ...) abort
  try
    " 1- clear the errors table
    if ! a:must_keep
      call s:errors.clear()
    endif
    " 2- define commands
    call s:DefineCommands()

    " 3- run every test
    let nok = 0
    let rtp = '.'
    let files = []
    for file in a:000
      let lFile = lh#path#is_absolute_path(file) ? [file] : lh#path#glob_as_list(rtp, file)
      if empty(lFile)
        let s:errors.qf += ["Cannot find file ".file." in ".getcwd()]
        let nok = 1
      endif
      call extend(files, lFile)
    endfor

    for file in files
      let nok = (s:RunOneFile(file) > 0) || nok
    endfor

    " 4- Clear the commands
    call s:UnDefineCommands()

  catch /.*/
    let nok = 1
  endtry

  " 5- Return the result
  let qf = s:errors.qf
  return [! nok, qf]
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
" VIM: let g:UTfiles='tests/lh/UT*.vim'
