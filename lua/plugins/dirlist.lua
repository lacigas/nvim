-- ================================================================================================
-- TITLE : DirList (local plugin)
-- ABOUT : Editable list of directory bookmarks. <CR> on an entry cd's into it and opens nvim-tree.
-- LINKS :
--   > source : <config>/local-plugins/dirlist.nvim
-- ================================================================================================

return {
	name = "DirList",
	dir = vim.fn.stdpath("config") .. "/local-plugins/dirlist.nvim",
	main = "dirlist",
	dependencies = { "nvim-tree/nvim-tree.lua" },
	cmd = { "DirList", "DirListAdd" },
	keys = {
		{ "<leader>db", "<cmd>DirList<cr>", desc = "DirList: Bookmarks" },
		{ "<leader>da", "<cmd>DirListAdd<cr>", desc = "DirList: Add cwd" },
	},
	opts = {
		categories = { "Work", "Tools", "Misc", "More" }, -- <Tab>/<S-Tab> or g1..g4 in the list
		-- file = vim.fn.stdpath("data") .. "/dirlist-%d.txt", -- %d = category number
		-- bookmarks = { "C:/tools/neovim", "~/projects" }, -- seeds category 1 on first use
		-- cd_command = "cd",   -- "cd" | "tcd" | "lcd"
		-- layout = "float",    -- "float" | "split"
		-- autosave = true,
		-- close_on_select = true,
	},
}
