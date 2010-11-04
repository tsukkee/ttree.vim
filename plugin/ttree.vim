let s:cpo_save = &cpo
set cpo&vim

augroup tree_view
    autocmd!
augroup END


let &cpo = s:cpo_save
