local M = {}

M.opts = {
  indent = { char = "│" },
  scope = { enabled = true, show_start = true, show_end = false },
  exclude = {
    filetypes = {
      "help",
      "alpha",
      "dashboard",
      "NvimTree",
      "Trouble",
      "lazy",
      "mason",
      "notify",
      "toggleterm",
      "gitcommit",
    }
  }
}

return M
