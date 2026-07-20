local utils = require "utils"

return {
  -- dependencies
  { "nvim-tree/nvim-web-devicons" },
  { "nvim-lua/plenary.nvim" },

  {
    "JoosepAlviste/palenightfall.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd "colorscheme palenightfall"
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function(_, opts)
      return utils.merge_opts(opts, require("config.nvimtree").opts)
    end,
    -- config = function(_, opts)
    --   require("config.nvimtree").config(_, opts)
    -- end
  },

  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require "config.lualine"
    end,
  },

  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require "config.bufferline"
    end,
  },

  {
    "nvim-mini/mini.nvim",
    version = "*",
    config = function()
      require "config.mini"
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = function(_, opts)
      return utils.merge_opts(opts, require("config.telescope").opts)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate | TSInstallAll",

    config = function()
      require "config.treesitter"
    end,
  },

  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = function(_, opts)
      return utils.merge_opts(opts, require("config.mason").opts)
    end,
  },
  { "mason-org/mason-lspconfig.nvim" },

  {
    "neovim/nvim-lspconfig",
    config = function()
      local servers = {
        "lua_ls",
        -- python
        "ruff",
        "basedpyright",
        "ty",
      }

      require("mason-lspconfig").setup { ensure_installed = servers }
      require("config.lspconfig").defaults()
      require("config.lspconfig").lspconfigs(servers)
    end,
  },

  {
    "stevearc/conform.nvim",
    ft = require("config.conform").ft,
    opts = function(_, opts)
      return utils.merge_opts(opts, require("config.conform").opts)
    end,
  },

  { "xzbdmw/colorful-menu.nvim" },
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    opts = function(_, opts)
      return utils.merge_opts(opts, require("config.blink-cmp").opts)
    end,
    opts_extend = function()
      return require("config.blink-cmp").opts_extend
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      return utils.merge_opts(opts, require("config.gitsigns").opts)
    end,
  },
}
