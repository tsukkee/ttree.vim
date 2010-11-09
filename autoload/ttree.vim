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

" Constants {{{
function! s:define(name, value)
    let s:{a:name} = a:value
    lockvar s:{a:name}
endfunction

call s:define('EXCEPTION_NAME', 'ttree: ')
call s:define('BUFFER_NAME', 'ttree')
call s:define('FILE_NODE_MARKER', '-')
call s:define('DIR_SEPARATOR', '/')
call s:define('CLOSE_DIR_MARKER', '+')
call s:define('OPEN_DIR_MARKER', '~')
call s:define('UPPER', '../')
call s:define('OFFSET', 0)
call s:define('EMPTY', {})
" }}}

" Customize {{{
function! s:set_default(variable_name, default)
    if !exists(a:variable_name)
        let {a:variable_name} = a:default
    endif
endfunction

call s:set_default('g:ttree_use_default_mappings', 1)
call s:set_default('g:ttree_width', 25)
call s:set_default('g:ttree_overwrite_statueline', 1)
call s:set_default('g:wont_open_dir_names', ['.git', '.hg', '.svn', '.bzr', 'CVS'])
" }}}

" Interface {{{
function! ttree#show(...)
    " get root path
    let resume = 0
    if a:0 > 1
        throw s:EXCEPTION_NAME . 'Too many arguments'
    elseif a:0 == 1 && !empty(a:1)
        let root_path = a:1
    elseif exists('t:ttree')
        let resume = 1
    else
        let root_path = getcwd()
    endif

    " tree belongs a tab
    if !exists('t:ttree')
        let t:ttree = s:Ttree.new(tabpagenr())
    endif

    " build root node
    if !resume
        let t:ttree.root = s:NodeFactory(root_path)
        call t:ttree.root.open()
    endif

    " show tree
    call t:ttree.show()
    call t:ttree.render()
    call s:key_mapping()
endfunction

function! ttree#hide()
    call t:ttree.hide()
endfunction

function! ttree#toggle(...)
    if exists('t:ttree') && t:ttree.is_shown()
        call ttree#hide()
    else
        call ttree#show(a:0 == 1 ? a:1 : '')
    endif
endfunction

function! ttree#get_node(...)
    if !exists('t:ttree')
        return s:EMPTY
    endif

    if a:0 > 1
        throw s:EXCEPTION_NAME . 'Too many arguments'
    elseif a:0 == 1 && type(a:1) == type(0)
        let lnum = a:1
    else
        let lnum = line('.')
    endif

    let index = lnum - 1 - s:OFFSET
    return (0 <= index && index < len(t:ttree.line2node))
    \   ? t:ttree.line2node[index]
    \   : s:EMPTY
endfunction

function! ttree#replace_netrw(path)
    if isdirectory(a:path)
        let s:ttree_should_not_split = 1
        call ttree#show(a:path)
    endif
endfunction
" }}}

" Utility {{{
" create indent
function! s:space(count)
    return repeat(' ', a:count)
endfunction

" toggle
function! s:toggle_directory(lnum)
    let node = ttree#get_node(a:lnum)
    if !empty(node) && node.is_dir
        call node.toggle()
        call t:ttree.render()
    endif
endfunction

" open
function! s:open_node(lnum)
    let node = ttree#get_node(a:lnum)
    if has_key(node, 'is_upper')
        call ttree#show(node.path)
    elseif node.is_dir
        call s:toggle_directory(a:lnum)
    elseif !empty(node)
        " move to last window
        if winnr('$') > 1
            wincmd p
        " when there is only ttree buffer, preserve ttree window
        else
            let w = winwidth(winnr()) - g:ttree_width
            execute 'botright' w 'vnew'
        endif
        execute 'edit' fnameescape(node.path)
    endif
endfunction

" toggle
function! s:toggle_show_dotfiles()
    let t:ttree.show_dotfiles = !t:ttree.show_dotfiles
    call t:ttree.render()
endfunction

" rebase
function! s:rebase(lnum)
    let node = ttree#get_node(a:lnum)
    if !empty(node) && node.is_dir
        call ttree#show(node.path)
        2
    endif
endfunction

" reload
function! s:reload()
    call t:ttree.reload()
    call t:ttree.render()
endfunction

" recursive open
function! s:_rec_open(node)
    call a:node.open()
    for node in a:node.children
        if node.is_dir && !node.wont_open
            call s:_rec_open(node)
        endif
    endfor
endfunction

function! s:recursive_open(lnum)
    echo "ttree: open recursively, please wait ..."
    redraw

    let node = ttree#get_node(a:lnum)
    if !node.is_dir
        return
    endif

    silent call s:_rec_open(node)
    call t:ttree.render()
endfunction

" recursive close
function! s:_rec_close(node)
    call a:node.close()
    for node in a:node.children
        if node.is_dir
            call s:_rec_close(node)
        endif
    endfor
endfunction

function! s:recursive_close(lnum)
    let node = ttree#get_node(a:lnum)
    if !node.is_dir
        return
    endif

    call s:_rec_close(node)
    call t:ttree.render()
endfunction


" key mapping
function! s:key_mapping()
    nnoremap <silent> <buffer> <Plug>(ttree:toggle_directory) :<C-u>call <SID>toggle_directory(line('.'))<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:recursive_open) :<C-u>call <SID>recursive_open(line('.'))<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:recursive_close) :<C-u>call <SID>recursive_close(line('.'))<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:open) :<C-u>call <SID>open_node(line('.'))<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:toggle_show_dotfiles) :<C-u>call <SID>toggle_show_dotfiles()<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:rebase) :<C-u>call <SID>rebase(line('.'))<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:reload) :<C-u>call <SID>reload()<CR>

    if g:ttree_use_default_mappings
        nmap <buffer> o <Plug>(ttree:toggle_directory)
        nmap <buffer> O <Plug>(ttree:recursive_open)
        nmap <buffer> X <Plug>(ttree:recursive_close)
        nmap <buffer> <CR> <Plug>(ttree:open)
        nmap <buffer> I <Plug>(ttree:toggle_show_dotfiles)
        nmap <buffer> C <Plug>(ttree:rebase)
        nmap <buffer> R <Plug>(ttree:reload)
    endif
endfunction
" }}}

" Ttree {{{
let s:Ttree = {
\   'root': {},
\   'bufnr': -1,
\   'bufname': '',
\   'show_dotfiles': 0,
\   'width': g:ttree_width,
\   'line2node': []
\}

function! s:Ttree.new(tabpagenr)
    let this = deepcopy(self)
    let this.bufname = s:BUFFER_NAME . a:tabpagenr
    return this
endfunction

function! s:Ttree.is_shown()
    return bufwinnr(self.bufnr) != -1
endfunction

function! s:Ttree.show()
    " buffer is not shown
    if !self.is_shown()
        " TODO: use topleft or botright?
        if !exists('s:ttree_should_not_split')
            execute 'topleft' self.width 'vnew' self.bufname
        else
            setlocal bufhidden=wipe
            execute 'edit' self.bufname
            unlet s:ttree_should_not_split
        endif

        let self.bufnr = bufnr('')

        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal nobuflisted
        setlocal noswapfile
        setlocal nomodifiable
        setlocal nomodeline
        setlocal nofoldenable
        setlocal foldcolumn=0
        setlocal nowrap
        setlocal nonumber

        if g:ttree_overwrite_statueline
            " TODO: reload
            let &l:statusline = 'ttree (' . t:ttree.root.path . ')'
        endif

        " fire FileType event for customization and hightlight
        setfiletype ttree
    " buffer has already shown
    else
        execute bufwinnr(self.bufnr) 'wincmd w'
    endif
endfunction

function! s:Ttree.hide()
    if self.is_shown()
        execute bufwinnr(self.bufnr) 'wincmd w'
        close
        wincmd p
    endif
endfunction

function! s:Ttree.render()
    setlocal modifiable
    let pos_save = getpos('.')

    % delete _
    let state = {
    \   'indent': 0,
    \   'lines': []
    \}
    let t:ttree.line2node = []

    " to upper
    let upper = s:UpperNode.new(self.root.path . '/../')
    call upper.render(state)

    " tree
    call self.root.render(state)
    call setline(1 + s:OFFSET, state.lines)

    call setpos('.', pos_save)
    setlocal nomodifiable
endfunction

function! s:Ttree.reload()
    call self.root.reload()
endfunction
" }}}

" Node {{{
let s:Node = {
\   'path': '',
\   'name': '',
\   'is_dir': 0,
\   '_is_symlink': -1,
\   'original': ''
\}

function! s:Node.new(path)
    let this = deepcopy(self)
    let this.path = a:path
    call this.initialize()
    return this
endfunction

function! s:Node.initialize()
endfunction

function! s:Node.is_symlink(path)
    if self._is_symlink == -1
        let self.original = resolve(a:path)
        let self._is_symlink = original != a:path
    endif
    return self._is_symlink
endfunction
" }}}

" FileNode {{{
let s:FileNode = deepcopy(s:Node)

function! s:FileNode.initialize()
    let self.name = fnamemodify(self.path, ':t')
endfunction

function! s:FileNode.render(state)
    call add(t:ttree.line2node, self)
    call add(a:state.lines,
    \   s:space(a:state.indent) . s:FILE_NODE_MARKER . self.name)
endfunction
" }}}

" DirNode {{{
let s:DirNode = extend(deepcopy(s:Node), {
\   'is_dir': 1,
\   'wont_open': 0,
\   'is_opened': 0,
\   'has_cached': 0,
\   'children': []
\})

function! s:DirNode.initialize()
    let self.name = fnamemodify(self.path[:-2], ':t')
    let self.wont_open = !empty(filter(copy(g:wont_open_dir_names), 'self.name ==# v:val'))
endfunction

function! s:DirNode.render(state)
    call add(t:ttree.line2node, self)

    if self.is_opened
        call add(a:state.lines,
        \   s:space(a:state.indent) . s:OPEN_DIR_MARKER . self.name . s:DIR_SEPARATOR)

        let a:state.indent += 1
        for node in self.children
            if !t:ttree.show_dotfiles && node.name =~ '^\.'
                continue
            else
                call node.render(a:state)
            endif
        endfor
        let a:state.indent -= 1
    else
        call add(a:state.lines,
        \   s:space(a:state.indent) . s:CLOSE_DIR_MARKER . self.name . s:DIR_SEPARATOR)
    endif
endfunction

function! s:DirNode.cache(force)
    if a:force || !self.has_cached
        let children = split(glob(self.path . '{.*,*}'), "\n")
        echo "ttree: caching" len(children) "nodes ..."
        redraw

        " delete non-existent node
        let i = 0
        for node in self.children
            if index(children, node.path) == -1
                call remove(self.children, i)
            else
                let i += 1
            endif
        endfor

        " add new node
        let i = 0
        for path in children
            if empty(filter(copy(self.children), 'v:val.path == path'))
                call insert(self.children, s:NodeFactory(path), i)
            endif
            let i += 1
        endfor
        let self.has_cached = 1

        echo "ttree: done!"
    endif
endfunction

function! s:DirNode.reload()
    if self.has_cached
        call self.cache(1)
    endif

    for node in self.children
        if node.is_dir
            call node.reload()
        endif
    endfor
endfunction

function! s:DirNode.open()
    call self.cache(0)
    let self.is_opened = 1
endfunction

function! s:DirNode.close()
    let self.is_opened = 0
endfunction

function! s:DirNode.toggle()
    if self.is_opened
        call self.close()
    else
        call self.open()
    endif
endfunction
" }}}

" UpperNode {{{
let s:UpperNode = extend(deepcopy(s:Node), {
\   'is_upper': 1
\})

function! s:UpperNode.initialize()
    let self.name = s:UPPER
endfunction

function! s:UpperNode.render(state)
    call add(t:ttree.line2node, self)
    call add(a:state.lines, self.name)
endfunction
" }}}

" Factory {{{
function! s:NodeFactory(path)
    let full_path = fnamemodify(a:path, ':p')
    if empty(glob(full_path))
        throw s:EXCEPTION_NAME . "File not found: " . a:path
    endif

    if isdirectory(full_path)
        return s:DirNode.new(full_path)
    else
        return s:FileNode.new(full_path)
    endif
endfunction
" }}}

let &cpo = s:cpo_save
