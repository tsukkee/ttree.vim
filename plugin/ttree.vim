let s:cpo_save = &cpo
set cpo&vim

augroup ttree
    autocmd!
    autocmd VimEnter * call s:define_unite_action()
augroup END

if exists('g:ttree_replace_netrw') && g:ttree_replace_netrw
    augroup ttree
        " remove netrw
        autocmd VimEnter * silent! autocmd! FileExplorer
        " open ttree
        autocmd BufEnter,VimEnter * call ttree#replace_netrw(expand('<amatch>'))
    augroup END
endif

function! s:dirname(path)
    return isdirectory(a:path) ? a:path : fnamemodify(a:path, ':p:h')
endfunction

function! s:define_unite_action()
    if !exists(':Unite')
        return
    endif

    let action = {
    \   'description': 'open ttree with selected item'
    \}
    function! action.func(candidate)
        call ttree#show(s:dirname(a:candidate.word))
    endfunction

    call unite#custom_action('file,directory', 'ttree', action)
endfunction

command! -nargs=? -complete=file TtreeShow call ttree#show(<q-args>)
command! -nargs=0 TtreeHide call ttree#hide()
command! -nargs=? TtreeToggle call ttree#toggle(<q-args>)

let &cpo = s:cpo_save
