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
