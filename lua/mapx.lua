-- Helper function to create nvim_set_keymap helper functions bound to a mode
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
    if opts.buffer ~= nil then
      local b = 0
      if type(opts.buffer) ~= 'boolean' then
        b = opts.buffer
      end
      opts.buffer = nil
      vim.api.nvim_buf_set_keymap(b, mode, lhs, rhs, opts)
    else
      vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
    end
  end
end

local mapx = {
  buffer = { buffer = true },
  nowait = { nowait = true },
  silent = { silent = true },
  script = { script = true },
  expr   = { expr   = true },
  unique = { unique = true },

  mapbang     = _map('!'),
  noremapbang = _map('!', { noremap = true }),
}

-- Create helper functions like `map`, `nnoremap`, `vmap`, etc.
for _, m in ipairs {'', 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't'} do
  mapx[m .. 'map'] = _map(m)
  mapx[m .. 'noremap'] = _map(m, { noremap = true })
end

return mapx
