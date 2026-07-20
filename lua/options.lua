local opt = vim.opt
local o = vim.o
local g = vim.g

g.netrw_banner = 0
o.nu = true
o.relativenumber = true

o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = true

o.wrap = false
o.smartindent = true
o.inccommand = "split"

o.splitbelow = true
o.splitright = true

opt.fillchars = { eob = " " }
o.ignorecase = true
o.smartcase = true
o.laststatus = 3
o.showmode = false
o.splitkeep = "screen"

o.swapfile = file
o.backup = false
o.undodir = vim.fn.stdpath "data" .. "/undodir"
o.timeoutlen = 400
o.undofile = true

o.updatetime = 250

o.clipboard = "unnamedplus"
o.cursorline = true
o.cursorlineopt = "number"
o.guicursor = ""
o.scrolloff = 8

o.colorcolumn = "0"
o.signcolumn = "yes"
o.cmdheight = 0
o.termguicolors = true
o.guicursor = "n-v-c:block-blinkon50-blinkoff50,i-ci-ve:ver25-blinkon50-blinkoff50,r-cr-o:hor20"

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  callback = function()
    vim.hl.on_yank()
  end,
})
