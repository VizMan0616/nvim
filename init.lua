require("vim._core.ui2").enable {}

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require "options"
require "filetypes"
require "config.lazy"
require "autocmds"
require "keymaps"
