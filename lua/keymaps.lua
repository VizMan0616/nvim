local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<leader>q", "<cmd>qa<CR>", { desc = "Exit VIM" })
map("n", "<leader>qs", "<cmd>wqa<CR>", { desc = "Exit VIM & save buffer" })

map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

map("n", "<leader>s", "<cmd>w<CR>", { desc = "Save buffer" })
map("n", "<leader>sa", "<cmd>wa<CR>", { desc = "Save all buffers" })

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Adding comments
map("n", "<leader>/", "gcc", { desc = "Toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "Toggle comment", remap = true })

-- nvimtree
map("n", "<leader>ec", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

--bufferline
map("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { noremap = true, silent = true, desc = "Move to next buffer" })
map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { noremap = true, silent = true, desc = "Move to next buffer" })
map("n", "<leader>x", function()
  local buffer = vim.api.nvim_get_current_buf()

  vim.cmd "bp"
  vim.cmd("bd" .. buffer)
end, { desc = "Close current buffer" })

-- telescope
local telescope_builtin = require "telescope.builtin"

map("n", "<leader>fw", telescope_builtin.live_grep, { desc = "telescope live grep" })
map("n", "<leader>fb", telescope_builtin.buffers, { desc = "telescope find buffers" })
map("n", "<leader>fo", function ()
  telescope_builtin.oldfiles { only_cwd = true }
end, { desc = "telescope find oldfiles" })
map("n", "<leader>fz", telescope_builtin.current_buffer_fuzzy_find, { desc = "telescope find in current buffer" })
map("n", "<leader>ff", telescope_builtin.find_files, { desc = "telescope find files" })
map(
  "n",
  "<leader>fa",
  function ()
    telescope_builtin.find_files { follow = true, no_ignore = true, hidden = true } 
  end,
  { desc = "telescope find all files" }
)

-- conform
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

-- lsp diagnostics
map("n", "<leader>ds", vim.diagnostic.open_float, { desc = "LSP show diagnostic float" })

-- only for python
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    -- This format imports
    map({ "n", "x" }, "<leader>fi", function()
      require("conform").format({
        async = true,
        lsp_fallback = true,
        formatters = { "ruff_organize_imports" },
      }, function()
        print "All imports were organized!"
      end)
    end, { buffer = true, desc = "Organize imports" })

    -- This remove unused imports
    map({ "n", "x" }, "<leader>fx", function()
      require("conform").format({
        async = true,
        lsp_fallback = true,
        formatters = { "ruff_remove_imports" },
      }, function()
        print "Unused imports cleaned!"
      end)
    end, { buffer = true, desc = "Remove unused imports" })

    -- This changes single quotes by double quotes
    map({ "n", "x" }, "<leader>fq", function()
      require("conform").format({
        async = true,
        lsp_fallback = true,
        formatters = { "ruff_fix_single_quotes" },
      }, function()
        print "' now is \"!"
      end)
    end, { buffer = true, desc = "Fix quote style" })
  end,
})
