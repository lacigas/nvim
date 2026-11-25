-- ================================================================================================
-- TITLE : DirList
-- ABOUT : Lists of directory bookmarks, grouped in categories. Every category is a real file opened
--         in a normal buffer, so it can be edited like any other text (one directory per line, `#`
--         starts a comment). <CR> on an entry changes the cwd to it and shows it in nvim-tree.
--         <Tab> / <S-Tab> cycle through the categories, g1..gN jump to one directly.
-- ================================================================================================

local M = {}

M.config = {
	-- Category names; their order gives the numbers used by g1..gN and :DirList N
	categories = { "General", "Work", "Tools", "Misc" },
	-- Bookmark file per category, `%d` is replaced by the category number
	file = vim.fn.stdpath("data") .. "/dirlist-%d.txt",
	-- Written to the file of category 1 the first time it is created
	bookmarks = {
		vim.fn.stdpath("config"),
		vim.fn.expand("~"),
	},
	-- Command used to change the directory: "cd" (global), "tcd" (tab) or "lcd" (window)
	cd_command = "cd",
	-- Write pending edits of the list before jumping to a directory or switching category
	autosave = true,
	-- Close the list window after selecting a directory
	close_on_select = true,
	-- "float" or "split"
	layout = "float",
	float = {
		width = 0.5, -- fraction of the editor width
		height = 0.4, -- fraction of the editor height
		border = "rounded",
	},
	-- Buffer-local keymaps inside the list (j / k are the normal motions)
	mappings = {
		select = "<CR>",
		close = { "q", "<Esc>" },
		next_category = "<Tab>",
		prev_category = "<S-Tab>",
		-- Prefix for jumping to a category by number: g1, g2, ...
		goto_category = "g",
	},
}

-- Single-file list used before categories existed; becomes category 1 on first use
local legacy_file = vim.fn.stdpath("data") .. "/dirlist.txt"

-- The open window is found again through the `w:dirlist` mark and the category is kept in
-- `g:dirlist_category`, so both survive a `:Lazy reload` (which starts with a fresh module).
local state = { win = nil, category = vim.g.dirlist_category or 1 }

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "DirList" })
end

local function file_for(category)
	return M.config.file:format(category)
end

local function ensure_file(category)
	local file = file_for(category)
	if vim.fn.filereadable(file) == 1 then
		return file
	end
	vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
	if category == 1 and vim.fn.filereadable(legacy_file) == 1 then
		vim.fn.rename(legacy_file, file)
		return file
	end
	local lines = {
		"# DirList: " .. M.config.categories[category] .. " - one directory per line, # starts a comment.",
		"# Edit freely and save with :w. <CR> jumps to a directory, <Tab>/<S-Tab> switch category.",
	}
	if category == 1 then
		vim.list_extend(lines, M.config.bookmarks)
	end
	vim.fn.writefile(lines, file)
	return file
end

--- Turns a line of the list into a directory path, or nil for blank/comment lines.
local function parse_line(line)
	line = vim.trim(line)
	if line == "" or line:sub(1, 1) == "#" then
		return nil
	end
	return vim.fn.fnamemodify(vim.fn.expand(line), ":p")
end

local function save_if_modified(buf)
	if M.config.autosave and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("silent write")
		end)
	end
end

local function is_open()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		return true
	end
	state.win = nil
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.w[win].dirlist then
			state.win = win
			return true
		end
	end
	return false
end

local function close_window()
	if is_open() then
		-- Closing the last window would quit Neovim; leave it open in that case
		if #vim.api.nvim_tabpage_list_wins(0) > 1 then
			vim.api.nvim_win_close(state.win, false)
		end
	end
	state.win = nil
end

--- Changes the cwd to `dir` and opens nvim-tree on it.
function M.jump(dir)
	if vim.fn.isdirectory(dir) == 0 then
		notify("Not a directory: " .. dir, vim.log.levels.WARN)
		return
	end
	vim.cmd(M.config.cd_command .. " " .. vim.fn.fnameescape(dir))

	local tree = require("nvim-tree.api").tree
	-- NvimTreeOpen ignores its path when the tree is already visible (it only focuses it),
	-- so re-root an open tree explicitly.
	if tree.is_visible() then
		tree.change_root(dir)
	end
	tree.open({ path = dir })
end

local function select_entry()
	local dir = parse_line(vim.api.nvim_get_current_line())
	if not dir then
		return
	end
	save_if_modified(vim.api.nvim_get_current_buf())
	if M.config.close_on_select then
		close_window()
	end
	M.jump(dir)
end

--- Shows the category names below the list (float footer, or winbar for a split).
local function render_categories()
	if not is_open() then
		return
	end
	local chunks = {}
	for i, name in ipairs(M.config.categories) do
		local hl = i == state.category and "DirListCategoryActive" or "DirListCategory"
		table.insert(chunks, { " " .. i .. " " .. name .. " ", hl })
		if i < #M.config.categories then
			table.insert(chunks, { " ", "FloatBorder" })
		end
	end

	if M.config.layout == "split" then
		local parts = {}
		for _, chunk in ipairs(chunks) do
			table.insert(parts, "%#" .. chunk[2] .. "#" .. chunk[1]:gsub("%%", "%%%%"))
		end
		vim.wo[state.win].winbar = table.concat(parts) .. "%#Normal#"
	else
		vim.api.nvim_win_set_config(state.win, { footer = chunks, footer_pos = "center" })
	end
end

local setup_buffer

local function load_category(category)
	local buf = vim.fn.bufadd(ensure_file(category))
	vim.fn.bufload(buf)
	vim.bo[buf].buflisted = false
	setup_buffer(buf)
	return buf
end

--- Shows category `category` in the open list window.
function M.switch_category(category)
	local count = #M.config.categories
	if not is_open() or category < 1 or category > count then
		return
	end
	save_if_modified(vim.api.nvim_win_get_buf(state.win))
	state.category = category
	vim.g.dirlist_category = category
	vim.api.nvim_win_set_buf(state.win, load_category(category))
	vim.wo[state.win].cursorline = true
	render_categories()
end

local function cycle_category(step)
	local count = #M.config.categories
	M.switch_category((state.category - 1 + step) % count + 1)
end

-- Runs every time a list is shown (not once per buffer), so the keymaps always call into the
-- current module, also after a `:Lazy reload`.
setup_buffer = function(buf)
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].commentstring = "# %s"

	local mappings = M.config.mappings
	local map = function(lhs, rhs, desc)
		if lhs and lhs ~= "" then
			vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, desc = desc })
		end
	end
	map(mappings.select, select_entry, "DirList: open directory")
	for _, lhs in ipairs(type(mappings.close) == "table" and mappings.close or { mappings.close }) do
		map(lhs, close_window, "DirList: close")
	end
	map(mappings.next_category, function()
		cycle_category(1)
	end, "DirList: next category")
	map(mappings.prev_category, function()
		cycle_category(-1)
	end, "DirList: previous category")
	if mappings.goto_category and mappings.goto_category ~= "" then
		for i, name in ipairs(M.config.categories) do
			map(mappings.goto_category .. i, function()
				M.switch_category(i)
			end, "DirList: " .. name)
		end
	end
end

local function open_window(buf)
	if M.config.layout == "split" then
		vim.cmd("botright split")
		vim.api.nvim_win_set_buf(0, buf)
		return vim.api.nvim_get_current_win()
	end
	local f = M.config.float
	local width = math.floor(vim.o.columns * f.width)
	local height = math.floor(vim.o.lines * f.height)
	return vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		-- one row up so the footer with the categories stays centred too
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		border = f.border,
		title = " DirList ",
		title_pos = "center",
		style = "minimal",
	})
end

--- Opens the list, on `category` if given, otherwise on the category used last.
function M.open(category)
	if category and (category < 1 or category > #M.config.categories) then
		notify("No category " .. category, vim.log.levels.WARN)
		return
	end
	if is_open() then
		vim.api.nvim_set_current_win(state.win)
		if category then
			M.switch_category(category)
		end
		return
	end
	state.category = category or state.category
	vim.g.dirlist_category = state.category
	state.win = open_window(load_category(state.category))
	vim.w[state.win].dirlist = true
	vim.wo[state.win].cursorline = true
	render_categories()
end

function M.toggle(category)
	if is_open() and not category then
		close_window()
	else
		M.open(category)
	end
end

--- Appends `dir` (default: cwd) to `category` (default: the current category).
function M.add(dir, category)
	category = category or state.category
	local name = M.config.categories[category]
	if not name then
		notify("No category " .. category, vim.log.levels.WARN)
		return
	end
	local file = ensure_file(category)
	dir = vim.fn.fnamemodify(vim.fn.expand((dir and dir ~= "") and dir or vim.fn.getcwd()), ":p")
	local buf = vim.fn.bufnr(file)
	local loaded = buf ~= -1 and vim.api.nvim_buf_is_loaded(buf)
	local lines = loaded and vim.api.nvim_buf_get_lines(buf, 0, -1, false) or vim.fn.readfile(file)
	for _, line in ipairs(lines) do
		if parse_line(line) == dir then
			notify("Already in " .. name .. ": " .. dir)
			return
		end
	end
	-- `:p` adds a trailing separator; keep the file tidy without it (but keep a bare root like C:\)
	dir = dir:gsub("([^:])[\\/]$", "%1")
	if loaded then
		-- Keep an open (possibly modified) list buffer in sync instead of writing behind its back
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, { dir })
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("silent write")
		end)
	else
		vim.fn.writefile({ dir }, file, "a")
	end
	notify("Added to " .. name .. ": " .. dir)
end

--- Adds the folder under the cursor in nvim-tree (the containing folder for a file).
function M.add_tree_node()
	local node = require("nvim-tree.api").tree.get_node_under_cursor()
	if not node or not node.absolute_path then
		return
	end
	local path = node.absolute_path
	if node.type ~= "directory" then
		path = vim.fn.fnamemodify(path, ":h")
	end
	M.add(path)
end

function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)
	-- Lists are replaced, not merged index by index
	for _, key in ipairs({ "categories", "bookmarks" }) do
		if opts[key] then
			M.config[key] = opts[key]
		end
	end
	if opts.mappings and opts.mappings.close then
		M.config.mappings.close = opts.mappings.close
	end
	M.config.file = vim.fn.expand(M.config.file)

	vim.api.nvim_set_hl(0, "DirListCategory", { link = "FloatFooter", default = true })
	vim.api.nvim_set_hl(0, "DirListCategoryActive", { link = "PmenuSel", default = true })

	vim.api.nvim_create_user_command("DirList", function(cmd)
		M.toggle(tonumber(cmd.args))
	end, { nargs = "?", desc = "Toggle the DirList bookmarks (optionally on category N)" })
	vim.api.nvim_create_user_command("DirListAdd", function(cmd)
		-- `:DirListAdd [N] [dir]`: a leading number picks the category
		local category, dir = cmd.args:match("^(%d+)%s*(.*)$")
		if category then
			M.add(dir, tonumber(category))
		else
			M.add(cmd.args)
		end
	end, { nargs = "*", complete = "dir", desc = "Add a directory (default: cwd) to DirList" })
end

return M
