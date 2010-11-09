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

if exists('b:current_syntax')
    finish
endif

syntax match ttreeUpdir /\%1l.*/

syntax match ttreeDirNode /^\s*[+~].\+\/$/
            \ contains=ttreeDirNodeMarker,ttreeDirNodeName,ttreeDirNodeSlash
syntax match ttreeDirNodeMarker /^\s*\zs[+~]/ contained
syntax match ttreeDirNodeSlash /\/\ze$/ contained

syntax match ttreeFileNode /^\s*\-.\+/
            \ contains=ttreeFileNodeMarker,ttreeFileNodeName
syntax match ttreeFileNodeMarker /^\s*\zs\-/


highlight default link ttreeUpdir String

highlight default link ttreeDirNode Directory
highlight default link ttreeDirNodeMarker Type
highlight default link ttreeDirNodeSlash Special

highlight default link ttreeFileNode Normal
highlight default link ttreeFileNodeMarker Type

let b:current_syntax = 'ttree'
