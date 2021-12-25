let g:vim_zettelkasten_path = expand('<sfile>')
let g:vim_zettelkasten_path = strpart(g:vim_zettelkasten_path, 0, strridx(g:vim_zettelkasten_path, "/"))
let g:vim_zettelkasten_path = strpart(g:vim_zettelkasten_path, 0, strridx(g:vim_zettelkasten_path, "/"))
call system("make -C" . g:vim_zettelkasten_path)
let g:vim_zettelkasten_header = g:vim_zettelkasten_path . "/build/header"
let g:vim_zettelkasten_csearch = g:vim_zettelkasten_path . "/build/csearch"
let g:vim_zettelkasten_rtree = g:vim_zettelkasten_path . "/build/rtree"
let g:vim_zettelkasten_history = []
let g:vim_zettelkasten_history_position = 0

command! VZKFollowLink call LinkAction()
command! VZKGoBackInHistory call GoBackInHistory()
command! VZKGoForwardInHistory call GoForwardInHistory()

autocmd FileType markdown map <buffer> <Return> :VZKFollowLink<CR>
autocmd FileType markdown setlocal autowrite
autocmd FileType markdown map <buffer> <BS> :VZKGoBackInHistory<CR>
autocmd FileType markdown map <buffer> zb :VZKGoForwardInHistory<CR>
autocmd FileType markdown syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
autocmd FileType markdown call AddFileToHistory(expand("%"))

command! VZKToggle call ToggleZettelkasten()
command! JumpToVZK exe bufwinnr("Zettelkasten") . "wincmd w"

function! Close()
	JumpToVZK
	hide
endfunction

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
	else
		let output = system(g:vim_zettelkasten_rtree . " . .md | " . g:vim_zettelkasten_header . " " . search . " | grep ' " . name . "' | awk '{ print $1 }' | " . g:vim_zettelkasten_header . " title | awk '{ first=$1; $1=\"\"; print $0, \"(\" first \")\" }'")
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
	setlocal nowrite
	vertical resize 50
	e Zettelkasten
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
		call Close()
	endif
endfunction


function! LinkAction()
	let name = synIDattr(synID(line('.'), col('.'), 1), 'name')

	if name == "markdownLinkText" || name == "markdownLinkTextDelimiter"
		normal f(
		let line = strpart(getline(line('.')), col('.'))
		let filepath = strpart(line, 0, strridx(line, ')'))
		execute 'e! ' . filepath
	elseif name == "markdownUrl" || name == "markdownLinkDelimiter"
		normal F(
		let line = strpart(getline(line('.')), col('.'))
		let filepath = strpart(line, 0, strridx(line, ')'))
		execute 'e! ' . filepath
	else
		if strlen(matchstr(getline(line('.'))[col('.') - 1], '\S'))
			normal viwdi[]
			normal hp
			normal f]li()
			startinsert
		endif
	endif
endfunction

function! GoBackInHistory()
	if g:vim_zettelkasten_history_position > 1
		let g:vim_zettelkasten_history_position -= 1
	endif

	execute 'e! ' . g:vim_zettelkasten_history[g:vim_zettelkasten_history_position - 1]
endfunction

function! GoForwardInHistory()
	if g:vim_zettelkasten_history_position < len(g:vim_zettelkasten_history)
		let g:vim_zettelkasten_history_position += 1
	endif
	execute 'e! ' . g:vim_zettelkasten_history[g:vim_zettelkasten_history_position - 1]
endfunction

function! AddFileToHistory(path)
	if g:vim_zettelkasten_history_position == 0
		call add(g:vim_zettelkasten_history, a:path)
		let g:vim_zettelkasten_history_position += 1
	elseif g:vim_zettelkasten_history[g:vim_zettelkasten_history_position - 1] != a:path
		call add(g:vim_zettelkasten_history, a:path)
		let g:vim_zettelkasten_history_position += 1
	endif
endfunction
