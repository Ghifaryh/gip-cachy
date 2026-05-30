-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Smartly close the current file tab without breaking Neo-tree splits or window layouts
vim.keymap.set("n", "<S-q>", function()
  -- Check if the modern Snacks library is available
  if Snacks and Snacks.bufdelete then
    Snacks.bufdelete()
  else
    -- Fallback safety measure if things are still loading
    vim.cmd("bdelete")
  end
end, { desc = "Smart Delete Buffer" })
