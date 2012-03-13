" {{{
" plugin/drupal.vim defines several useful strings in b:Drupal_info.
" There is no such thing as buffer-local environment variables, so call this
" each time you enter a Drupal buffer.
augroup Drupal
  autocmd! BufEnter <buffer> if strlen(b:Drupal_info.DRUPAL_ROOT) |
	\ let $DRUPAL_ROOT = b:Drupal_info.DRUPAL_ROOT | endif
augroup END
" }}}

if strlen(b:Drupal_info.CORE)
  let &l:tags .= ',' . expand('<sfile>:p:h:h') . '/drupal' . b:Drupal_info.CORE . '.tags'
endif
