local bufferline = require "bufferline"
-- local utils = require "utils"

-- local ok, palehightfall = pcall(require, "palenightfall")
-- local base_bg = (ok and palehightfall.colors and palehightfall.colors.background) or "#252837"

-- local darker_bg = utils.darken_hex(base_bg, 0.90)

bufferline.setup {
  options = {
    mode = "buffers",
    style_preset = bufferline.style_preset.no_italic,
    separator_style = "slope",
    sort_by = "insert_at_end",
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(count, level, diagnostics_dict, context)
      local icon = level:match "error" and " " or " "
      return " " .. icon .. count
    end,
    indicator = { style = "underline" },
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        text_align = "left",
        separator = true,
      },
    },
    name_formatter = function(buf)
      return buf.name
    end,
    custom_filter = function(buf_number)
      if vim.fn.bufname(buf_number) == "" then
        local lines = vim.api.nvim_buf_get_lines(buf_number, 0, -1, false)
        if #lines == 1 and lines[1] == "" then
          return false
        end
      end
      return true
    end,
  },
}
