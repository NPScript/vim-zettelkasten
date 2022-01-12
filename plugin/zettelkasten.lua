zettelkasten = {}
zettelkasten.history = {}

local banner_string = {
'╻ ╻╻┏┳┓   ╺━┓┏━╸╺┳╸╺┳╸┏━╸╻  ╻┏ ┏━┓┏━┓╺┳╸┏━╸┏┓╻',
'┃┏┛┃┃┃┃╺━╸┏━┛┣╸  ┃  ┃ ┣╸ ┃  ┣┻┓┣━┫┗━┓ ┃ ┣╸ ┃┗┫',
'┗┛ ╹╹ ╹   ┗━╸┗━╸ ╹  ╹ ┗━╸┗━╸╹ ╹╹ ╹┗━┛ ╹ ┗━╸╹ ╹'
}

local get_header = function(path)
	local content = {}
	local file = io.open(path)
	io.input(file)

	if (io.read() == '---')
	then
		local line = io.read()
		while not (line == '---')
		do
			for k, v in line:gmatch("([^:]+)%s*:%s*(.+)") do
				content[k] = v
			end

			line = io.read()
		end
	end


	io.close(file)

	return content
end

local get_all_files = function()
	local f = io.popen("find -name '*.md'")
	local files = {}

	io.input(f)
	local line = io.read()

	while line do
		table.insert(files, line)
		line = io.read()
	end

	io.close(f)

	return files
end

local get_file_with_header_match = function(key, value)
	local files = {}

	for _, v in pairs(get_all_files()) do
		if (get_header(v)[key]) then
			if (string.find(string.lower(get_header(v)[key]), string.lower(value))) then
				table.insert(files, v)
			end
		end
	end

	return files
end

local open_window = function(win_height)
	zettelkasten.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(zettelkasten.buf, 'bufhidden', 'wipe')


	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	local win_width = 46

	local row = 5
	local col = math.ceil((width - win_width) / 2)

	local opts = {
		style = "minimal",
		relative = "editor",
		border = {"│", "━" ,"│", "│", "╯", "─", "╰", "│"},
		width = win_width,
		height = win_height,
		row = row,
		col = col
	}

	zettelkasten.win = vim.api.nvim_open_win(zettelkasten.buf, true, opts)

	vim.fn.matchadd("Conceal", "-> [^ ]*$")
end

local close_window = function()
	vim.api.nvim_win_close(zettelkasten.win, true)
end

zettelkasten.left = function()
	if vim.api.nvim_get_current_win() == zettelkasten.win then
		close_window()
		zettelkasten.closed()
	end
end

local open_banner = function()
	zettelkasten.banner_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(zettelkasten.banner_buf, 'bufhidden', 'wipe')

	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	local win_height = 3
	local win_width = 46

	local row = 1
	local col = math.ceil((width - win_width) / 2)

	local opts = {
		style = "minimal",
		relative = "editor",
		border = "rounded",
		width = win_width,
		height = win_height,
		row = row,
		col = col
	}

	zettelkasten.banner_win = vim.api.nvim_open_win(zettelkasten.banner_buf, true, opts)

	vim.api.nvim_buf_set_lines(zettelkasten.banner_buf, 0, 3, false, banner_string)

end

zettelkasten.closed = function()
	vim.api.nvim_win_close(zettelkasten.banner_win, true)
	zettelkasten.banner_win = nil
	zettelkasten.banner_buf = nil
	zettelkasten.win = nil
	zettelkasten.buf = nil
end

local get_all_tags = function()
	local tags = {}

	for _, v in pairs(get_all_files()) do
		if (get_header(v)['tag']) then
			for s in vim.gsplit(get_header(v)['tag'], " ", false) do
				if not (vim.tbl_contains(tags, s)) then
					table.insert(tags, s)
				end
			end
		end
	end

	return tags
end

zettelkasten.add_to_history = function(path)
	zettelkasten.history = { last = zettelkasten.history, path = path }
end

zettelkasten.open_file = function()
	local line = vim.api.nvim_get_current_line()
	local path = line:gmatch('[^ ]*$')()
	close_window()
	vim.cmd("edit " .. path)
	zettelkasten.add_to_history(path)
end

zettelkasten.back = function()
	local last = zettelkasten.history.last
	if last.last then
		zettelkasten.history = { last = last.last, path = last.path  }
	end
	vim.cmd("edit " .. zettelkasten.history.path)
end

zettelkasten.find_tag = function()
	vim.ui.input("Search Tag: ", function(item)
		if (item == nil) then
			return
		end

		local files = get_file_with_header_match('tag', item)
		local lines = {}

		for i, s in pairs(files) do
			local header = get_header(s)
			table.insert(lines, header['title'] .. " " .. header['tag'] .. " -> " .. s);
		end

		local nol = vim.tbl_count(lines)

		if (zettelkasten.win == nil) then
			open_banner()
			open_window(nol)
			vim.cmd("autocmd WinClosed " .. zettelkasten.win .. " VZKClosed")
			vim.cmd("autocmd WinLeave * VZKLeaved")
			vim.cmd("map <buffer> <silent> <Return> :VZKOpenFile<CR>")
		end

		vim.api.nvim_buf_set_lines(zettelkasten.buf, 0, nol, false, lines)
	end)
end

zettelkasten.link_action = function()
	local v = vim.fn
	local name = v.synIDattr(v.synID(v.line("."), v.col("."), 1), "name")

	if name == "markdownLinkDelimiter" then
		vim.cmd("normal h")
		name = v.synIDattr(v.synID(v.line("."), v.col("."), 1), "name")
	end

	if name == "markdownLinkTextDelimiter" or name == "markdownLinkText" then
		vim.cmd("normal f(")
	elseif name ~= "markdownUrl" then
		vim.cmd("normal viws[]")
		vim.cmd("normal hp")
		vim.cmd("normal f]a()")
		vim.cmd("normal h")
		return
	end

	vim.cmd("normal gf")
	zettelkasten.add_to_history(vim.fn.expand("%"))
end

zettelkasten.show_history = function()

	local lines = {}

	local i = zettelkasten.history
	while i.last do
		local header = get_header(i.path)
		local title = header['title']
		local tag = header['tag']

		if not title then
			title = "~"
		end

		if not tag then
			tag = "~"
		end

		table.insert(lines, title .. " " .. tag .. " -> " .. i.path);
		i = i.last
	end

	local nol = vim.tbl_count(lines)

	if (zettelkasten.win == nil) then
		open_banner()
		open_window(nol)
		vim.cmd("autocmd WinClosed " .. zettelkasten.win .. " VZKClosed")
		vim.cmd("autocmd WinLeave * VZKLeaved")
		vim.cmd("map <buffer> <silent> <Return> :VZKOpenFile<CR>")
	end

	vim.api.nvim_buf_set_lines(zettelkasten.buf, 0, nol, false, lines)
end

zettelkasten.buf = nil
zettelkasten.win = nil
zettelkasten.banner_buf = nil
zettelkasten.banner_win = nil

vim.cmd("command! VZKClosed lua zettelkasten.closed()")
vim.cmd("command! VZKLeaved lua zettelkasten.left()")
vim.cmd("command! VZKFindTag lua zettelkasten.find_tag()")
vim.cmd("command! VZKOpenFile lua zettelkasten.open_file()")
vim.cmd("command! VZKBackInHistory lua zettelkasten.back()")
vim.cmd("command! VZKHistory lua zettelkasten.show_history()")
vim.cmd("command! VZKLink lua zettelkasten.link_action()")
vim.cmd("autocmd FileType markdown setlocal autowrite")
vim.cmd("autocmd FileType markdown syn region markdownLink matchgroup=markdownLinkDelimiter start='(' end=')' contains=markdownUrl keepend contained conceal")
vim.cmd("autocmd FileType markdown map <buffer> <silent> <Return> :VZKLink<CR>")
vim.cmd("autocmd FileType markdown map <buffer> <silent> <BS> :VZKBackInHistory<CR>")
