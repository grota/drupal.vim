" vim: set foldmethod=marker:

" Autocommands {{{
augroup Drupal
  " Remove ALL autocommands for the Drupal group.
  autocmd!
  " s:DrupalInit() will create the buffer-local Dictionary b:Drupal_info
  " containing useful information for ftplugins and syntax files.  It will
  " also add drupal as a secondary filetype.  This will load the ftplugins and
  " syntax files drupal.vim after the usual ones.
  autocmd FileType php,css,javascript,drini call s:DrupalInit()
augroup END
" }}}

let s:slash = !exists("+shellslash") || &shellslash ? '/' : '\'

" {{{ @function s:DrupalInit()
" Save some information in the buffer-local Dictionary b:Drupal_info for use
" by ftplugin and syntax scripts.  The keys are
" - DRUPAL_ROOT
"   path to the Drupal root
" - INFO_FILE
"   path to the .info file of the containing module, theme, etc.
" - TYPE
"   'module' or 'theme' or 'make'
" - OPEN_COMMAND
"   'open' or 'xdg-open' or 'cmd /c start', depending on the OS
" In all cases, the values will be '' if we cannot make a reasonable guess.
" {{{
function! s:DrupalInit()
  " Expect something like /var/www/drupal-7.9/sites/all/modules/ctools
  let path = expand('%:p')
  let directory = fnamemodify(path, ':h')
  let info = {'DRUPAL_ROOT': s:DrupalRoot(directory),
	\ 'INFO_FILE': s:InfoPath(directory)}
  let info.OPEN_COMMAND = s:OpenCommand()
  let info.TYPE = s:IniType(info.INFO_FILE)
  let info.CORE = s:CoreVersion(info.INFO_FILE)
  " If we found only one of CORE and DRUPAL_ROOT, use it to get the other.
  if info.CORE == '' && info.DRUPAL_ROOT != ''
    let INFO_FILE = info.DRUPAL_ROOT . '/modules/system/system.info'
    if filereadable(INFO_FILE)
      let info.CORE = s:CoreVersion(INFO_FILE)
    endif
  elseif info.DRUPAL_ROOT == '' && info.CORE != ''  && exists('g:Drupal_dirs')
    let info.DRUPAL_ROOT = get(g:Drupal_dirs, info.CORE, '')
  endif

  " @var b:Drupal_info
  let b:Drupal_info = info

  "if b:Drupal_info.DRUPAL_ROOT !=# ''
    set ft+=.drupal
  "endif
endfun
" }}} }}}

" {{{ @function s:DrupalRoot()
" Try to guess which part of the path is the Drupal root directory.
"
" @param path
"   A string representing a system path.
"
" @return
"   A string representing the Drupal root, '' if not found.
" {{{
function! s:DrupalRoot(path)
  let markers = ['index.php', 'cron.php', 'modules', 'themes', 'sites']
  " On *nix, start with '', but on Windows typically start with 'C:'.
  let droot = matchstr(a:path, '[^\' . s:slash . ']*')
  for part in split(matchstr(a:path, '\' . s:slash . '.*'), s:slash)
    let droot .= s:slash . part
    " This would be easier if it did not have to work on Windows.
    let ls = glob(droot . s:slash . '*') . "\<C-J>"
    let is_drupal_root = 1
    for marker in markers
      if match(ls, '\' . s:slash . marker . "\<C-J>") == -1
	let is_drupal_root = 0
	break
      endif
    endfor
    " If all the markers are there, then this looks like a Drupal root.
    if is_drupal_root
      return droot
    endif
  endfor
  return ''
endfun
" }}} }}}

" {{{ @function s:InfoPath()
" Try to find the .info file of the module, theme, etc. containing a path.
"
" @param path
"   A string representing a system path.
"
" @return
"   A string representing the path of the .info file, '' if not found.
" {{{
function! s:InfoPath(path)
  let dir = a:path
  while dir =~ '\' . s:slash
    let infopath = glob(dir . s:slash . '*.{info,make,build}')
    if strlen(infopath)
      return infopath
    endif
    " No luck yet, so go up one directory.
    let dir = substitute(dir, '\' . s:slash . '[^\' . s:slash . ']*$', '', '')
  endwhile
  return ''
endfun
" }}} }}}

" @function s:OpenCommand() {{{
" Return a string that can be used to open URL's (and other things).
" Usage:
" let open = s:OpenCommand()
" if strlen(open) | execute '!' . open . ' http://example.com' | endif
" See http://www.dwheeler.com/essays/open-files-urls.html
function! s:OpenCommand()
if has('macunix') && executable('open')
  return 'open'
endif
if has('win32unix') && executable('cygstart')
  return 'cygstart'
endif
if has('unix') && executable('xdg-open')
  return 'xdg-open'
endif
if (has('win32') || has('win64')) && executable('cmd')
  return 'cmd /c start'
endif
  return ''
endfun
"}}}

" {{{ @function s:CoreVersion(info_path)
" Find the version of Drupal core by parsing the .info file.
"
" @param info_path
"   A string representing the path to the .info file.
"
" @return
"   A numeric string representing the Drupal core version.
" {{{
function! s:CoreVersion(info_path)
  " Find the Drupal core version.
  if a:info_path == '' || !filereadable(a:info_path)
    return ''
  endif
  let lines = readfile(a:info_path, '', 500)
  let core_re = '^\s*core\s*=\s*\zs\d\+\ze\.x\s*$'
  let core_line = matchstr(lines, core_re)
  return matchstr(core_line, core_re)
endfun
" }}} }}}

" {{{ @function s:IniType(info_path)
" Find the type (module, theme, make) by parsing the path.
"
" @param info_path
"   A string representing the path to the .info file.
"
" @return
"   A string:  module, theme, make
" {{{
" TODO:  How do we recognize a Profiler .info file?
function! s:IniType(info_path)
  let ext = fnamemodify(a:info_path, ':e')
  if ext == 'make' || ext == 'build'
    return 'make'
  else
    " If the extension is not 'info' at this point, I do not know how we got
    " here.
    let m_index = strridx(a:info_path, s:slash . 'modules' . s:slash)
    let t_index = strridx(a:info_path, s:slash . 'themes' . s:slash)
    " If neither matches, try a case-insensitive search.
    if m_index == -1 && t_index == -1
      let m_index = matchend(a:info_path, '\c.*\' . s:slash . 'modules\' . s:slash)
      let t_index = matchend(a:info_path, '\c.*\' . s:slash . 'themes\' . s:slash)
    endif
    if m_index > t_index
      return 'module'
    elseif m_index < t_index
      return 'theme'
    endif
    " We are not inside a themes/ directory, nor a modules/ directory.  Do not
    " guess.
    return ''
  endif
endfun
" }}} }}}
