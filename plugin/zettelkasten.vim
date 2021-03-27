
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
	call Write("Search Result")
	let name = ""
	let search = a:search

	if strlen(a:search)
		let name = input("/" . a:search . "/")
	else
		let name = input("/")
		let search = split(name, "/")[0]
		let name = split(name, "/")[1]
	endif

	let output = ""

	if search == "[content]"
		let output = system(g:vim_zettelkasten_rtree . " . .md | " . g:vim_zettelkasten_csearch . " '" . name . "' | " . g:vim_zettelkasten_header . " title | awk '{ first=$1; $1=\"\"; print $0, \"(\" first \")\" }'")
	elseif
		let output = system(g:vim_zettelkasten_rtree . ". .md | " . g:vim_zettelkasten_header . " " . search . " | grep ' " . name . "' | awk '{ print $1 }' | " . g:vim_zettelkasten_header . " title | awk '{ first=$1; $1=\"\"; print $0, \"(\" first \")\" }'")
	endif

	for i in split(output, '\n')
		call Write("    " . i)
	endfor
endfunction

function! GetCursorFilePath()
	let l=getline(line('.'))
	let bi=strridx(l, "(")
	let ci=strridx(l, ")")
	let l=strpart(l, bi + 1, ci - bi - 1)
	return l
endfunction

function! OpenFile()
	let path = GetCursorFilePath()
	if strlen(path)
		let n=winnr()
		silent execute 'wincmd l'
		if winnr() == n
			vnew
		elseif &modified
			new
		endif
		silent execute 'n ' . path
	endif
endfunction

function! SplitFile()
	let path = GetCursorFilePath()
	if strlen(path)
		vnew
		silent execute 'n ' . path
	endif
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
	setlocal splitright
	vertical resize 50
	file Zettelkasten
	call MakeHighlight()
	call Header()
	map <silent> <buffer> q ZQ
	map <silent> <buffer> /t :call Search("tag")<CR>
	map <silent> <buffer> // :call Search("")<CR>
	map <silent> <buffer> <Enter> :call OpenFile()<CR>
	map <silent> <buffer> s :call SplitFile()<CR>
endfunction

function! ToggleZettelkasten()
	let n = bufwinnr("Zettelkasten")
	if n < 0
		call OpenBuffer()
	else
		bdelete "Zettelkasten"
	endif
endfunction

let g:vim_zettelkasten_path = expand('<sfile>')
let g:vim_zettelkasten_path = strpart(g:vim_zettelkasten_path, 0, strridx(g:vim_zettelkasten_path, "/"))
let g:vim_zettelkasten_path = strpart(g:vim_zettelkasten_path, 0, strridx(g:vim_zettelkasten_path, "/"))
call system("make -C" . g:vim_zettelkasten_path)
let g:vim_zettelkasten_header = g:vim_zettelkasten_path . "/build/header"
let g:vim_zettelkasten_csearch = g:vim_zettelkasten_path . "/build/csearch"
let g:vim_zettelkasten_rtree = g:vim_zettelkasten_path . "/build/rtree"

command! ToggleZettelkasten call ToggleZettelkasten()

function! LinkAction()
	let name = synIDattr(synID(line('.'), col('.'), 1), 'name')

	if name == "markdownLinkText"
		normal f(
		let line = strpart(getline(line('.')), col('.'))
		let filepath = strpart(line, 0, strridx(line, ')'))
		execute 'e! ' . filepath

	else
		" Create New Link
	endif
endfunction

autocmd! FileType markdown omap <silent> <buffer> <Return> :call LinkAction()<CR>
autocmd! FileType markdown syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal

