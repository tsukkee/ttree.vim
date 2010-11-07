let s:cpo_save = &cpo
set cpo&vim

augroup ttree
    autocmd!
augroup END

let &cpo = s:cpo_save
