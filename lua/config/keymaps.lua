
-- Title : Neovim Keymaps
-- About : sets some keymaps
-- ================================================================================ 
--

-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "next search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "half page up (centered)" })

-- Buffer navigation
-- format on save using efm langserver and configured formatters
local lsp_fmt_group = vim.api.nvim_create_augroup("FormatOnSaveGroup", {})
vim.api.nvim_create_autocmd("BufWritePre", {
	group = lsp_fmt_group,
	callback = function()
		local efm = vim.lsp.get_clients({ name = "efm" })
		if vim.tbl_isempty(efm) then
			return
		end
		vim.lsp.buf.format({ name = "efm", async = true })
	end,
})
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer"})
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer"})

-- window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window"})
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window"})
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window"})
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window"})

-- Splitting and Resizing
vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split window vertically"})
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split window horizontally"})
vim.keymap.set("n", "<C-Up>", "<Cmd>resize -2<CR>", { desc = "Decrease window height"})
vim.keymap.set("n", "<C-Down>", "<Cmd>resize +2<CR>", { desc = "Increase window height"})
vim.keymap.set("n", "<C-Left>", "<Cmd>vertical resize +2<CR>", { desc = "Increase window width"})
vim.keymap.set("n", "<C-Right>", "<Cmd>vertical resize -2<CR>", { desc = "Decrease window width"})

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect"})
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect"})

-- Better J behaviour
vim.keymap.set("n", "J", "mzJ`z", { desc = "joins lines and keeps cursor position"})

-- Quick config editing
vim.keymap.set("n", "<leader>rc", "<Cmd>e ~/.config/nvim/init.lua<CR>", { desc = "Edit config" })

-- File Explorer
vim.keymap.set("n", "<leader>m", "<Cmd>NvimTreeFocus<CR>", { desc = "Focus on File Explorer" })
vim.keymap.set("n", "<leader>e", "<Cmd>NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })

