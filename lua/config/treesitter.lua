local treesitter = require("nvim-treesitter")
local files = require("paths").Filetypes.ForTreesitter

treesitter.setup {
  install_dir = vim.fn.stdpath("data") .. "/site",
  highlight = {enable = true},
  indent = {enable = true},
}

treesitter.install(files)
