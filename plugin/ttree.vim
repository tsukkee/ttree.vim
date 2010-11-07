let s:cpo_save = &cpo
set cpo&vim

augroup ttree
    autocmd!
augroup END

command! -nargs=? -complete=file TtreeShow call ttree#show(<q-args>)
command! -nargs=0 TtreeHide call ttree#hide()
command! -nargs=? TtreeToggle call ttree#toggle(<q-args>)

let &cpo = s:cpo_save
