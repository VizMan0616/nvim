local M = {}

local DEVELOPMENT_CONTAINER_NAME = "odoo_development"
local HOME_DIR = vim.fn.expand "$HOME"
local UBUNTU = {
  FOCAL = { "focal", "20.04" },
  JAMMY = { "jammy", "22.04" },
  NOBLE = { "noble", "24.04" },
}
local ODOO_CONFIGS = {
  ["16"] = { odoo = "16.0", os = UBUNTU.JAMMY },
  ["17"] = { odoo = "17.0", os = UBUNTU.JAMMY },
  ["18"] = { odoo = "18.0", os = UBUNTU.NOBLE },
  ["19"] = { odoo = "19.0", os = UBUNTU.NOBLE },
}

local lockfile_path = vim.fn.stdpath "config" .. "/lazy-lock.json"

local function copy(obj, seen)
  if type(obj) ~= "table" then
    return obj
  end
  if seen and seen[obj] then
    return seen[obj]
  end

  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res

  for k, v in pairs(obj) do
    res[copy(k, s)] = copy(v, s)
  end
  return res
end

local function check_container_running(container_pattern, format)
  local ps_format = {
    ["image"] = ".Image",
    ["names"] = ".Names",
  }

  local cmd = {
    "docker",
    "ps",
    "--format",
    '"{{' .. ps_format[format] .. '}}"',
  }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code == 1 then
    return false, result.stderr
  end
  if result.stdout ~= "" and result.stdout:match(container_pattern) then
    return true, result.stdout
  end

  return false, ""
end

local function wrap_line(line, max_len)
  if vim.fn.strdisplaywidth(line) <= max_len then
    return { line }
  end

  local wrapped = {}
  local current = ""

  for word in line:gmatch "%S+" do
    if current == "" then
      current = word
    else
      local test = current .. " " .. word
      if vim.fn.strdisplaywidth(test) <= max_len then
        current = test
      else
        table.insert(wrapped, current)
        current = word
      end
    end
  end

  if current ~= "" then
    table.insert(wrapped, current)
  end

  return wrapped
end

function M.get_lockfile_commits()
  local f = io.open(lockfile_path, "r")
  if not f then
    return {}
  end

  local content = f:read "*a"
  f:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return {}
  end

  local commits = {}
  for plugin_name, info in pairs(decoded) do
    if type(info) == "table" and info.commit then
      commits[plugin_name] = info.commit
    end
  end
  return commits
end

function M.show_blame()
  local filepath = vim.api.nvim_buf_get_name(0)

  if filepath == "" then
    vim.notify("Buffer has no file path", vim.log.levels.WARN)
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]

  local blame_res = vim
    .system({ "git", "blame", "-L", line .. "," .. line, "--porcelain", "--", filepath }, { text = true })
    :wait()

  if blame_res.code ~= 0 or not blame_res.stdout or blame_res.stdout == "" then
    vim.notify("Not in a git repository or file is untracked", vim.log.levels.WARN)
    return
  end

  local commit_hash = blame_res.stdout:match "^([a-f0-9]+)"
  if not commit_hash or commit_hash:match "^0+$" then
    vim.notify("Not commited yet", vim.log.levels.INFO)
    return
  end

  -- Pass commit_hash so git inspects the exact line commit
  local show_res = vim
    .system(
      { "git", "show", "-s", "--format=%an%x1f%ae%x1f%ad%x1f%h%x1f%B", "--date=format:%Y-%m-%d %H:%M:%S", commit_hash },
      { text = true }
    )
    :wait()

  if show_res.code ~= 0 or not show_res.stdout then
    vim.notify("Failed to fetch commit details", vim.log.levels.ERROR)
    return
  end

  local parts = vim.split(show_res.stdout, "\x1f", { plain = true })
  if #parts < 5 then
    vim.notify("Unexpected git response format", vim.log.levels.ERROR)
    return
  end

  local blame_info = {
    author = parts[1],
    author_email = parts[2],
    date = parts[3],
    short_hash = parts[4],
    raw_msg = parts[5],
  }
  local header = {
    left = " " .. blame_info.author,
    right = "<" .. blame_info.author_email .. ">",
  }
  header.left_w = vim.fn.strdisplaywidth(header.left)
  header.right_w = vim.fn.strdisplaywidth(header.right)

  local TARGET_MAX_WIDTH = math.min(80, math.floor(vim.o.columns * 0.75) - 2)

  local msg_lines = {}
  for _, l in ipairs(vim.split(blame_info.raw_msg, "\n", { plain = true })) do
    l = l:gsub("\r$", "")
    if l == "" then
      table.insert(msg_lines, "")
    else
      local wrapped_lines = wrap_line(l, TARGET_MAX_WIDTH)
      for _, wl in ipairs(wrapped_lines) do
        table.insert(msg_lines, wl)
      end
    end
  end

  while #msg_lines > 0 and msg_lines[#msg_lines] == "" do
    table.remove(msg_lines)
  end

  local max_content_width = header.left_w + header.right_w + 2
  for _, l in ipairs(msg_lines) do
    local w = vim.fn.strdisplaywidth(l)
    if w > max_content_width then
      max_content_width = w
    end
  end

  local footer_min_width = vim.fn.strdisplaywidth(blame_info.date) + vim.fn.strdisplaywidth(blame_info.short_hash) + 4
  if footer_min_width > max_content_width then
    max_content_width = footer_min_width
  end

  local total_width = max_content_width + 2
  if total_width < 45 then
    total_width = 45
  end

  local space_count_header = total_width - 2 - header.left_w - header.right_w
  if space_count_header < 1 then
    space_count_header = 1
  end
  local header_fmt = " " .. header.left .. string.rep(" ", space_count_header) .. header.right .. " "

  local delimiter = string.rep("─", total_width)

  local padded_msg_lines = {}
  for _, l in ipairs(msg_lines) do
    local pad_right = total_width - 1 - vim.fn.strdisplaywidth(l)
    table.insert(padded_msg_lines, " " .. l .. string.rep(" ", math.max(0, pad_right)))
  end

  local space_count_footer = total_width
    - 2
    - vim.fn.strdisplaywidth(blame_info.date)
    - vim.fn.strdisplaywidth(blame_info.short_hash)
  if space_count_footer < 1 then
    space_count_footer = 1
  end
  local footer_fmt = " " .. blame_info.date .. string.rep(" ", space_count_footer) .. blame_info.short_hash .. " "

  local contents = {}
  table.insert(contents, header_fmt)
  table.insert(contents, delimiter)
  for _, l in ipairs(padded_msg_lines) do
    table.insert(contents, l)
  end
  table.insert(contents, delimiter)
  table.insert(contents, footer_fmt)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, contents)
  vim.bo[buf].filetype = "gitcommit"

  local ns = vim.api.nvim_create_namespace "git_blame_inspector"

  -- Highlight ranges
  vim.hl.range(buf, ns, "Title", { 0, 0 }, { 0, -1 })
  vim.hl.range(buf, ns, "FloatBorder", { 1, 0 }, { 1, -1 })

  if #padded_msg_lines > 0 then
    vim.hl.range(buf, ns, "Normal", { 2, 0 }, { 2, -1 })
    for i = 3, 1 + #padded_msg_lines do
      vim.hl.range(buf, ns, "Comment", { i, 0 }, { i, -1 })
    end
  end

  local delimi2_idx = 2 + #padded_msg_lines
  vim.hl.range(buf, ns, "FloatBorder", { delimi2_idx, 0 }, { delimi2_idx, -1 })

  local footer_idx = delimi2_idx + 1
  vim.hl.range(buf, ns, "Comment", { footer_idx, 0 }, { footer_idx, -1 })

  local max_win_height = math.min(#contents, math.floor(vim.o.lines * 0.7))

  local win_opts = {
    relative = "cursor",
    row = 1,
    col = 0,
    width = total_width,
    height = max_win_height,
    style = "minimal",
    border = "single",
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
end

function M.merge_opts(opts, to_merge_table)
  local copy_opts = copy(opts)

  for k, v in pairs(to_merge_table) do
    copy_opts[k] = v
  end
  return copy_opts
end

function M.darken_hex(hex, factor)
  if not hex then
    return nil
  end

  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16) or 0
  local g = tonumber(hex:sub(3, 4), 16) or 0
  local b = tonumber(hex:sub(5, 6), 16) or 0

  return string.format(
    "#%02x%02x%02x",
    math.floor(r * factor + 0.5),
    math.floor(g * factor + 0.5),
    math.floor(b * factor + 0.5)
  )
end

function M.check_if_odoo_container_is_running()
  return check_container_running("%-odoo", "image")
end

function M.check_if_odoo_development_image_exists(odoo_version)
  local pattern = "odoo%-" .. odoo_version .. "%-development"
  if odoo_version ~= nil then
    odoo_version = "19"
  end

  local cmd = {
    "docker",
    "image",
    "ls",
    "--format",
    '"{{ .Repository }}"',
  }
  local result = vim.system(cmd, { text = true }):wait()

  if result.code == 1 then
    return false, result.stderr
  end
  if result.stdout ~= "" and string.find(result.stdout, pattern) then
    return true, result.stdout
  end

  return false, ""
end

function M.check_development_image_path_exists()
  local development_image_parent = HOME_DIR .. "/Productivity/Personal/odoo-base-docker"
  local development_image_abs_path = development_image_parent .. "/Dockerfile"

  local development_image_parent_exists = vim.fn.isdirectory(development_image_parent) == 1
  local development_image_abs_path_exists = vim.fn.filereadable(development_image_abs_path) == 1

  return development_image_parent_exists and development_image_abs_path_exists
end

function M.kill_odoo_development_container()
  local cmd = { "docker", "stop", DEVELOPMENT_CONTAINER_NAME }

  local is_running, _ = check_container_running(DEVELOPMENT_CONTAINER_NAME, "names")
  if not is_running then
    return
  end

  vim.system(cmd):wait()
end

function M.remove_odoo_development_container()
  local rm_cmd = { "docker", "rm", DEVELOPMENT_CONTAINER_NAME }
  -- local container_rm_cmd = { 'docker', 'container', 'rm', DEVELOPMENT_CONTAINER_NAME }

  local is_running, _ = check_container_running(DEVELOPMENT_CONTAINER_NAME, "names")
  if is_running then
    M.kill_odoo_development_container()
  end

  vim.system(rm_cmd):wait()
  -- vim.system(container_rm_cmd):wait()
end

function M.run_odoo_development_image(odoo_version, work_dir)
  local image_exist, _ = M.check_if_odoo_development_image_exists(odoo_version)
  local cmd = {
    "docker",
    "run",
    "-d",
    "--name",
    DEVELOPMENT_CONTAINER_NAME,
    "-v",
    work_dir .. ":" .. work_dir,
    "odoo-" .. odoo_version .. "-development:latest",
    "sleep",
    "infinity",
  }

  if not image_exist then
    vim.notify "No image to run!"
    return
  end

  M.remove_odoo_development_container()
  vim.system(cmd):wait()
end

function M.build_odoo_development_image(odoo_version)
  local configs = ODOO_CONFIGS[odoo_version]
  local cmd = {
    "docker",
    "build",
    "--build-arg",
    "UBUNTU_IMAGE=" .. configs.os[1],
    "--build-arg",
    "UBUNTU_VERSION=" .. configs.os[1],
    "--build-arg",
    "ODOO_VERSION=" .. configs.odoo,
    "--build-arg",
    "ODOO_RELEASE=latest",
    "--target",
    "odoo-devel",
    "--tag",
    "odoo-" .. odoo_version .. "-development:latest",
    "--file",
    HOME_DIR .. "/Productivity/Personal/odoo-base-docker/Dockerfile",
    ".",
  }
  local result = vim.system(cmd):wait()

  if result.code == 1 then
    vim.notify("Image was not able to be built due to some unexpected error.\n\n" .. result.stderr)
  else
    vim.notify "Image built successfully!"
  end
end

M.development_container_name = DEVELOPMENT_CONTAINER_NAME
M.lang_identation = {
  lua = 2,
  javascript = 2,
  typescript = 2,
  javascriptreact = 2,
  typescriptreact = 2,
  json = 2,
  html = 2,
  css = 2,
  scss = 2,
  yaml = 2,
  markdown = 2,
  python = 4,
}

return M
