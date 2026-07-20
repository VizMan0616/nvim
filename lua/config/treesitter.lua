local treesitter = require("nvim-treesitter")

treesitter.setup {
  install_dir = vim.fn.stdpath("data") .. "/site",
  highlight = {enable = true},
  indent = {enable = true},
}

local ensure_installed = {
  "lua", "vim", "luadoc", "vimdoc", "printf",
  "markdown", "markdown_inline", "html", "xml", "yaml",
  "dockerfile", "gitignore", "query", "bash"
}
treesitter.install(ensure_installed)
