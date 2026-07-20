local bufferline = require "bufferline"
bufferline.setup {
  options = {
    mode = "buffers",
    style_preset = bufferline.style_preset.no_italic,
    separator_style = "slope",
    sort_by = "insert_at_end",
    indicator = { style = "underline" },
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        text_align = "left",
        separator = true,
      },
    },
    highlights = {
      fill = { guibg = "NONE", ctermbg = "NONE" },
      background = { guibg = "NONE", ctermbg = "NONE" },
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
