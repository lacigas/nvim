-- Minimal, dependency-free emoji picker for Neovim
-- Usage: require("emoji_picker").pick()  (mapped below)

local M = {}

-- A compact default set (add your favorites!)
local emoji_list = {
  { "😀", "grinning face" },
  { "😂", "face with tears of joy" },
  { "😊", "smiling face with smiling eyes" },
  { "😍", "smiling face with heart-eyes" },
  { "😎", "smiling face with sunglasses" },
  { "🤔", "thinking face" },
  { "😘", "face blowing a kiss" },
  { "😢", "crying face" },
  { "😡", "pouting face" },
  { "👍", "thumbs up" },
  { "👎", "thumbs down" },
  { "👏", "clapping hands" },
  { "🙏", "folded hands" },
  { "🔥", "fire" },
  { "✨", "sparkles" },
  { "⚡", "high voltage" },
  { "✅", "check mark" },
  { "❌", "cross mark" },
  { "💡", "light bulb" },
  { "💻", "laptop" },
  { "🧠", "brain" },
  { "📝", "memo" },
  { "📌", "pushpin" },
  { "📎", "paperclip" },
  { "🔍", "magnifying glass" },
  { "🔧", "wrench" },
  { "🎯", "bullseye" },
  { "🎉", "party popper" },
  { "❤️", "red heart" },
  { "💙", "blue heart" },
  { "💚", "green heart" },
  { "💛", "yellow heart" },
  { "💜", "purple heart" },
}

local function make_items()
  local items = {}
  for _, e in ipairs(emoji_list) do
    local symbol, name = e[1], e[2]
    table.insert(items, { text = symbol .. "  " .. name, emoji = symbol })
  end
  return items
end

-- Insert text at cursor (handles normal/insert)
local function insert_text(text)
  local mode = vim.api.nvim_get_mode().mode
  if mode == "i" or mode == "ic" then
    vim.api.nvim_put({ text }, "c", true, true)
  else
    vim.api.nvim_put({ text }, "c", false, true)
  end
end

function M.pick(opts)
  opts = opts or {}
  local items = make_items()

  -- Optional simple filter by substring in the description
  local search = opts.search
  if search and #search > 0 then
    local filtered = {}
    local s = search:lower()
    for _, it in ipairs(items) do
      if it.text:lower():find(s, 1, true) then
        table.insert(filtered, it)
      end
    end
    items = filtered
  end

  vim.ui.select(items, {
    prompt = "Select emoji",
    format_item = function(item) return item.text end,
  }, function(choice)
    if not choice then return end
    if opts.copy == true then
      -- Copy to system clipboard (+ register)
      vim.fn.setreg("+", choice.emoji)
      if opts.insert ~= false then insert_text(choice.emoji) end
      vim.notify("Copied emoji to clipboard: " .. choice.emoji, vim.log.levels.INFO)
    else
      insert_text(choice.emoji)
    end
  end)
end

return M
