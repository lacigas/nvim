return {
  {
    name = "local-emoji-picker",
    dir = vim.fn.stdpath("config"), -- ← THIS IS THE FIX
    lazy = false,
    config = function()
      vim.g.mapleader = vim.g.mapleader or " "

      vim.keymap.set("n", "<leader>ue", function()
        require("utils.emoji_picker").pick()
      end, { desc = "Emoji Picker (built-in)" })

      vim.keymap.set("n", "<leader>uE", function()
        require("utils.emoji_picker").pick({ copy = true })
      end, { desc = "Emoji Picker (copy + insert)" })
    end,
  },
}