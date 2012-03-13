" *.inc, *.module files can already be detected by vim's default $VIMRUNTIME/filetype.vim
"
" Drupal module files
au BufRead,BufNewFile *.install,*.profile,*.theme,*.engine,*.test
	\ if getline(1) =~ '<?php' |
	\   setf php |
	\ endif

autocmd BufRead,BufNewFile *.{info,make,build} setf drini
