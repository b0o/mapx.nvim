local mapx = {
  globalized = false,
  buffer = { buffer = true },
  nowait = { nowait = true },
  silent = { silent = true },
  script = { script = true },
  expr   = { expr   = true },
  unique = { unique = true },
}

local fns = {}

local function _map(mode, _opts)
  return function(lhs, rhs, ...)
    local merge = { _opts }
    for i = 1, select('#', ...) do
      local o = select(i, ...)
      table.insert(merge, o)
    end
    local opts = {}
    for _, o in ipairs(merge) do
      if type(o) == 'string' then
        opts[o] = true
      else
        for k, v in pairs(o) do
          opts[k] = v
        end
      end
    end
    local lhss = lhs
    if type(lhs) ~= "table" then
      lhss = {lhs}
    end
    for _, l in ipairs(lhss) do
      if opts.buffer ~= nil then
        local b = 0
        if type(opts.buffer) ~= 'boolean' then
          b = opts.buffer
        end
        opts.buffer = nil
        vim.api.nvim_buf_set_keymap(b, mode, l, rhs, opts)
      else
        vim.api.nvim_set_keymap(mode, l, rhs, opts)
      end
    end
  end
end

local function bind(source, target, force)
  local force = force or false
  for k, v in pairs(source) do
    if target[k] ~= nil then
      local msg = "mapx.bind: overwriting key " .. k .. " on " .. string.format('%s', target)
      if force then
        print("warning: " .. msg .. " {force = true}")
      else
        error(msg)
      end
    end
    target[k] = v
  end
  return target
end

local function init()
  local force = force or false
  for _, mode in ipairs {'', 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't'} do
    local m = mode .. 'map'
    local n = mode .. 'noremap'
    fns[m] = _map(mode)
    fns[n] = _map(mode, { noremap = true })
  end
  fns.mapbang     = _map('!')
  fns.noremapbang = _map('!', { noremap = true })
  bind(fns, mapx)
  return mapx
end

function mapx.globalize(force)
  if not mapx.globalized then
    bind(fns, _G, force)
    mapx.globalized = true
  end
  return mapx
end

return init()
