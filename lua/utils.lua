local M = {}

local function copy(obj, seen)
  if type(obj) ~= "table" then return obj end
  if seen and seen[obj] then return seen[obj] end

  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res

  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

M.merge_opts = function(opts, to_merge_table)
  local copy_opts = copy(opts)

  for k, v in pairs(to_merge_table) do copy_opts[k] = v end
  return copy_opts
end
return M
