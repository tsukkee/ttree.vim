" Constants {{{
let s:EXCEPTION_NAME = 'ttree: '
let s:BUFFER_NAME = 'ttree'
let s:FILE_NODE_MARKER = '~'
let s:CLOSE_DIR_MARKER = '-'
let s:OPEN_DIR_MARKER = '+'
let s:UPPER = '../'
let s:OFFSET = 0
let s:EMPTY = {}
" }}}

" Customize {{{
let s:width = 25
" }}}

" Interface {{{
function! ttree#show(...)
    " get root path
    let resume = 0
    if a:0 > 1
        throw s:EXCEPTION_NAME . 'Too many arguments'
    elseif a:0 == 1
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

function! ttree#get_node(lnum)
    if !exists('t:ttree')
        return s:EMPTY
    endif

    let index = a:lnum - 1 - s:OFFSET
    return (0 <= index && index < len(t:ttree.line2node))
    \   ? t:ttree.line2node[index]
    \   : s:EMPTY
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
    elseif !empty(node)
        wincmd p
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
    endif
endfunction

" reload
function! s:reload()
endfunction

" key mapping
function! s:key_mapping()
    nnoremap <silent> <buffer> <Plug>(ttree:toggle_directory) :<C-u>call <SID>toggle_directory(line('.'))<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:open) :<C-u>call <SID>open_node(line('.'))<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:toggle_show_dotfiles) :<C-u>call <SID>toggle_show_dotfiles()<CR>
    nnoremap <silent> <buffer> <Plug>(ttree:rebase) :<C-u>call <SID>rebase(line('.'))<CR>

    nmap <buffer> o <Plug>(ttree:toggle_directory)
    nmap <buffer> <CR> <Plug>(ttree:open)
    nmap <buffer> I <Plug>(ttree:toggle_show_dotfiles)
    nmap <buffer> C <Plug>(ttree:rebase)
endfunction
" }}}

" Ttree {{{
let s:Ttree = {
\   'root': {},
\   'bufnr': -1,
\   'bufname': '',
\   'show_dotfiles': 0,
\   'width': s:width,
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
        execute self.width 'vnew' self.bufname
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

function! s:Ttree.toggle()
    if !self.is_shown()
        call self.show()
    else
        call self.hide()
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
let s:DirNode = deepcopy(s:Node)
let s:DirNode.is_dir = 1
let s:DirNode.is_opened = 0
let s:DirNode.has_cached = 0
let s:DirNode.children = []

function! s:DirNode.initialize()
    let self.name = fnamemodify(self.path[:-2], ':t') . '/'
endfunction

function! s:DirNode.render(state)
    call add(t:ttree.line2node, self)

    if self.is_opened
        call add(a:state.lines,
        \   s:space(a:state.indent) . s:OPEN_DIR_MARKER . self.name)

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
        \   s:space(a:state.indent) . s:CLOSE_DIR_MARKER . self.name)
    endif
endfunction

function! s:DirNode.open()
    if !self.has_cached
        for path in split(glob(self.path . '{.*,*}'), "\n")
            call add(self.children, s:NodeFactory(path))
        endfor
        let self.has_cached = 1
    endif
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
let s:UpperNode = deepcopy(s:Node)
let s:UpperNode.is_upper = 1

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
