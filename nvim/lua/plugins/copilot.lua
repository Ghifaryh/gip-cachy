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
      filetypes = {
        -- Explicitly target environment configuration files
        sh = function(bufnr)
          -- If the filename ends with or contains .env, turn Copilot completely OFF
          if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(bufnr)), "^%.env") then
            return false
          end
          return true -- Allow standard shell scripts to work normally
        end,

        -- You can also forcefully turn it off for other plain text extensions if you want
        text = false,
        -- markdown = false,
        help = false,
        -- gitcommit = false,
        gitrebase = false,
        cvs = false,
        ["."] = false,
      },
    })
  end,
}
