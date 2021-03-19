
function! Clear()
	setlocal modifiable
	call deletebufline("Zettelkasten", 1, line("$"))
	setlocal nomodifiable
endfunction

function! Header()
	setlocal modifiable
	call setbufline("Zettelkasten", 1, "  Zettelkasten")
	call setbufline("Zettelkasten", 2, "")
	setlocal nomodifiable
endfunction

function! Write(arg)
	setlocal modifiable
	call setbufline("Zettelkasten", line('$') + 1, a:arg)
	setlocal nomodifiable
endfunction

function! Search(search)
	call Clear()
	call Header()
	let name = ""
	let search = a:search

	if strlen(a:search)
		let name = input("/" . a:search . "/")
	else
		let name = input("/")
		let search = split(name, "/")[0]
		let name = split(name, "/")[1]
	endif

	let output = system("rtree . .md | " . g:header . " " . search . " | grep ' " . name . "' | awk '{ print $1 }' | " . g:header . " title | awk '{ first=$1; $1=\"\"; print $0, \"(\" first \")\" }'")

	for i in split(output, '\n')
		call Write("    " . i)
	endfor
endfunction

function! OpenFile()
	let l=getline(line('.'))
	let bi=strridx(l, "(")
	let ci=strridx(l, ")")
	let l=strpart(l, bi + 1, ci - bi - 1)
	let n=winnr()
	silent execute 'wincmd l'
	if winnr() == n
		silent execute 'vertical new'
	elseif &modified
		silent execute 'new'
	endif
	silent execute 'n '. l
endfunction


function! MakeHighlight()
	call matchadd("Comment", "^  Zettelkasten")
	call matchadd("Comment", "([^)]*)")
endfunction

function! OpenBuffer()
	vertical topleft new
	setlocal nobuflisted
	setlocal nonumber
	setlocal nowrap
	setlocal buftype=nofile
	vertical resize 50
	file Zettelkasten
	call MakeHighlight()
	call Header()
	map <silent> <buffer> q ZQ
	map <silent> <buffer> /t :call Search("tag")<CR>
	map <silent> <buffer> // :call Search("")<CR>
	map <silent> <buffer> <Enter> :call OpenFile()<CR>
endfunction

function! ToggleZettelkasten()
	let n = bufwinnr("Zettelkasten")
	if n < 0
		call OpenBuffer()
	else
		bdelete "Zettelkasten"
	endif
			
endfunction

let g:project = expand('<sfile>')
let g:project = strpart(g:project, 0, strridx(g:project, "/"))
let g:project = strpart(g:project, 0, strridx(g:project, "/"))
call system("make -C" . g:project)
let g:header = g:project . "/build/header"

command ToggleZettelkasten call ToggleZettelkasten()
