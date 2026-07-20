local M = {}

local DEVELOPMENT_CONTAINER_NAME = 'odoo_development'
local HOME_DIR = vim.fn.expand('$HOME')
local UBUNTU = {
  FOCAL = { "focal", "20.04" },
  JAMMY = { "jammy", "22.04" },
  NOBLE = { "noble", "24.04" }
}
local ODOO_CONFIGS = {
  ["16"] = { odoo = "16.0", os = UBUNTU.JAMMY },
  ["17"] = { odoo = "17.0", os = UBUNTU.JAMMY },
  ["18"] = { odoo = "18.0", os = UBUNTU.NOBLE },
  ["19"] = { odoo = "19.0", os = UBUNTU.NOBLE }
}

local function copy(obj, seen)
  if type(obj) ~= "table" then return obj end
  if seen and seen[obj] then return seen[obj] end

  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res

  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

local function check_container_running(container_pattern, format)
  local ps_format = {
    ['image'] = '.Image',
    ['names'] = '.Names'
  }

  local cmd = {
    'docker',
    'ps',
    '--format',
    '"{{' .. ps_format[format] .. '}}"',
  }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code == 1 then return false, result.stderr end
  if result.stdout ~= "" and result.stdout:match(container_pattern) then
    return true, result.stdout
  end

  return false, ""
end

function M.merge_opts(opts, to_merge_table)
  local copy_opts = copy(opts)

  for k, v in pairs(to_merge_table) do copy_opts[k] = v end
  return copy_opts
end

function M.check_if_odoo_container_is_running()
  return check_container_running('%-odoo', 'image')
end

function M.check_if_odoo_development_image_exists(odoo_version)
  local pattern = 'odoo%-' .. odoo_version .. '%-development'
  if odoo_version ~= nil then
    odoo_version = "19"
  end

  local cmd = {
    'docker',
    'image',
    'ls',
    '--format',
    '"{{ .Repository }}"',
  }
  local result = vim.system(cmd, { text = true }):wait()

  if result.code == 1 then return false, result.stderr end
  if result.stdout ~= "" and string.find(result.stdout, pattern) then
    return true, result.stdout
  end

  return false, ""
end

function M.check_development_image_path_exists()
  local development_image_parent = os.getenv("HOME") .. "/Productivity/Personal/odoo-base-docker"
  local development_image_abs_path = development_image_parent .. "/Dockerfile"

  local development_image_parent_exists = vim.fn.isdirectory(development_image_parent) == 1
  local development_image_abs_path_exists = vim.fn.filereadable(development_image_abs_path) == 1

  return development_image_parent_exists and development_image_abs_path_exists
end

function M.kill_odoo_development_container()
  local cmd = { 'docker', 'stop', DEVELOPMENT_CONTAINER_NAME }

  local is_running, _ = check_container_running(DEVELOPMENT_CONTAINER_NAME, 'names')
  if not is_running then
    return
  end

  vim.system(cmd):wait()
end

function M.remove_odoo_development_container()
  local rm_cmd = { 'docker', 'rm', DEVELOPMENT_CONTAINER_NAME }
  -- local container_rm_cmd = { 'docker', 'container', 'rm', DEVELOPMENT_CONTAINER_NAME }

  local is_running, _ = check_container_running(DEVELOPMENT_CONTAINER_NAME, 'names')
  if is_running then
    M.kill_odoo_development_container()
  end

  vim.system(rm_cmd):wait()
  -- vim.system(container_rm_cmd):wait()
end

function M.run_odoo_development_image(odoo_version, work_dir)
  local image_exist, _ = M.check_if_odoo_development_image_exists(odoo_version)
  local cmd = {
      'docker',
      'run',
      '-d',
      '--name',
      DEVELOPMENT_CONTAINER_NAME,
      '-v',
      work_dir .. ':' .. work_dir,
      'odoo-' .. odoo_version .. '-development:latest',
      'sleep',
      'infinity'
  }

  if not image_exist then
    vim.notify('No image to run!')
    return
  end

  M.remove_odoo_development_container()
  vim.system(cmd):wait()
end

function M.build_odoo_development_image(odoo_version)
  local configs = ODOO_CONFIGS[odoo_version]
  local cmd = {
    'docker',
    'build',
    '--build-arg',
    'UBUNTU_IMAGE=' .. configs.os[1],
    '--build-arg',
    'UBUNTU_VERSION=' .. configs.os[1],
    '--build-arg',
    'ODOO_VERSION=' .. configs.odoo,
    '--build-arg',
    'ODOO_RELEASE=latest',
    '--target',
    'odoo-devel',
    '--tag',
    'odoo-' .. odoo_version.. '-development:latest',
    '--file',
    HOME_DIR .. '/Productivity/Personal/odoo-base-docker/Dockerfile',
    '.'
  }
  local result = vim.system(cmd):wait()

  if result.code == 1 then
    vim.notify("Image was not able to be built due to some unexpected error.\n\n" .. result.stderr)
  else
    vim.notify("Image built successfully!")
  end
end

M.development_container_name = DEVELOPMENT_CONTAINER_NAME

return M

