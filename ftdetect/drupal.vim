" *.inc, *.module files can already be detected by vim's default $VIMRUNTIME/filetype.vim
"
" Drupal module files
au BufRead,BufNewFile *.install,*.profile,*.theme,*.engine,*.test,*.module
	\ if getline(1) =~ '<?php' |
	\   setl ft=php.drupal |
	\ endif

autocmd BufRead,BufNewFile *.{info,make,build} setf drini.drupal
