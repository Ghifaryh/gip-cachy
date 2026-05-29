return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter", -- Only load when you actually start typing code
  config = function()
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = true, -- Automatically shows the faint ghost text as you type
        debounce = 75,
        keymap = {
          accept = "<M-l>", -- Alt + l to accept the suggestion (change to whatever you like)
          next = "<M-]>", -- Alt + ] to cycle to the next suggestion
          prev = "<M-[>", -- Alt + [ to cycle to the previous suggestion
          dismiss = "<C-]>", -- Ctrl + ] to hide the suggestion
        },
      },
      panel = { enabled = false }, -- Disable the heavy pop-up panel since Avante replaces this functionality
    })
  end,
}
