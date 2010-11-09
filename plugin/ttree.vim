" ttree.vim: light-weight tree view for vim
" Version:     0.0.1
" Last Change: 10 Nov 2010
" Author:      tsukkee <takayuki0510+ttree_vim at gmail.com>
" Licence:     The MIT License {{{
"     Permission is hereby granted, free of charge, to any person obtaining a copy
"     of this software and associated documentation files (the "Software"), to deal
"     in the Software without restriction, including without limitation the rights
"     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
"     copies of the Software, and to permit persons to whom the Software is
"     furnished to do so, subject to the following conditions:
"
"     The above copyright notice and this permission notice shall be included in
"     all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
"     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
"     THE SOFTWARE.
" }}}

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
