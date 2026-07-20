local pairs_config = {
  modes = { insert = true, command = false, terminal = false },
  mappings = {
    ["("] = { action = "open", pair = "()", neigh_pattern = "^[^\\]" },
    ["["] = { action = "open", pair = "[]", neigh_pattern = "^[^\\]" },
    ["{"] = { action = "open", pair = "{}", neigh_pattern = "^[^\\]" },

    [")"] = { action = "close", pair = "()", neigh_pattern = "^[^\\]" },
    ["]"] = { action = "close", pair = "[]", neigh_pattern = "^[^\\]" },
    ["}"] = { action = "close", pair = "{}", neigh_pattern = "^[^\\]" },

    ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "^[^\\]", register = { cr = false } },
    ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "^[^%a\\]", register = { cr = false } },
    ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "^[^\\]", register = { cr = false } },
  },
}

local notify_config = {
  content = {
    format = function(notif)
      return notif.msg
    end,
  },
  window = {
    config = function()
      return {
        title = "",
        anchor = "SE",
        row = vim.o.lines - 2,
        col = vim.o.columns,
        border = "single",
      }
    end,
  },
}

local cmdline_config = {
  autocomplete = {
    enable = true,
    delay = 50,
    predicate = nil,
    map_arrows = true,
  },
  autocorrect = {
    enable = true,
    func = nil,
  },
  autopeek = {
    enable = true,
    n_context = 1,
    predicate = nil,
    window = {
      config = { border = "single" },
      statuscolumn = nil,
    },
  },
}

-- Setup of mini plugins
require("mini.cmdline").setup(cmdline_config)
require("mini.pairs").setup(pairs_config)
require("mini.notify").setup(notify_config)
