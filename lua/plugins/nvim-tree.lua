-- ================================================================================================
-- TITLE : nvim-tree.lua
-- ABOUT : A file explorer tree for Neovim, written in Lua.
-- LINKS :
--   > github : https://github.com/nvim-tree/nvim-tree.lua
-- ================================================================================================

return {
	"nvim-tree/nvim-tree.lua",
	lazy = false,
	config = function()
		-- Remove background color from the NvimTree window (ui fix)
		vim.cmd([[hi NvimTreeNormal guibg=NONE ctermbg=NONE]])

		require("nvim-tree").setup({
			filters = {
				dotfiles = false, -- Show hidden files (dotfiles)
			},
      update_focused_file = {
        enable = true,
        update_root = true,
      },

			view = {
			},
			on_attach = function(bufnr)
				local api = require("nvim-tree.api")
				api.config.mappings.default_on_attach(bufnr)

				vim.keymap.set("n", "ga", function()
					require("dirlist").add_tree_node()
				end, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "nvim-tree: Add folder to DirList" })

				-- Open Neogit for the repo containing the node under the cursor
				vim.keymap.set("n", "gn", function()
					local node = api.tree.get_node_under_cursor()
					if not node or not node.absolute_path then
						return
					end
					local path = node.type == "directory" and node.absolute_path
						or vim.fn.fnamemodify(node.absolute_path, ":h")
					require("neogit").open({ cwd = path, kind = "vsplit" })
				end, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "nvim-tree: Neogit here" })
			end,
		})
	end,
}
