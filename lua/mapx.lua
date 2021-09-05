local mapx = {}
local mapopts = {
  buffer = { buffer = 0 },
  nowait = { nowait = true },
  silent = { silent = true },
  script = { script = true },
  expr   = { expr   = true },
  unique = { unique = true },
}
local state = {
  config = {
    debug = false,
    quiet = false,
    global = false,
    whichkey = false,
  },
  setup = false,
  globalized = false,
  whichkey = nil,
  groupOpts = nil,
  funcs = {},
  ftmaps = {},
}

vim.cmd([[
  augroup mapx
    autocmd!
    autocmd VimEnter * lua require'mapx'._handleVimEnter()
  augroup END
]])

local function dbg(...)
  if not state.config.debug then return end
  local function getpwin()
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
     if vim.fn.win_gettype(w) == "preview" then
       return w
     end
   end
  end
  local pwin = getpwin()
  if pwin == nil then
    vim.cmd(string.format("pedit +%s mapx_debug", table.concat({
      'setlocal',
      'nomodifiable',
      'buftype=nofile',
      'bufhidden=hide',
      'nobuflisted',
      'noswapfile',
      'nonumber',
      'norelativenumber',
      'nomodeline',
      'nolist',
      'scrolloff=0',
    }, "\\ ")))
    pwin = getpwin()
  end
  if pwin == nil then
    print(...)
    return
  end
  local msg = string.format("[%s] %s\n", os.date "%H:%M:%S", table.concat({...}, " "))
  local pbuf = vim.api.nvim_win_get_buf(pwin)
  vim.api.nvim_buf_set_option(pbuf, "modifiable", true)
  vim.api.nvim_buf_set_lines(pbuf, -1, -1, false, vim.split(msg, "\n", true))
  vim.api.nvim_buf_set_option(pbuf, "modifiable", false)
  vim.api.nvim_win_set_cursor(pwin, {vim.api.nvim_buf_line_count(pbuf), 0})
end

local function dbgi(...)
  if not state.config.debug then return end
  local msg = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    if type(v) == "table" or type(v) == "function" or type(v) == "thread" or type(v) == "userdata" then
      table.insert(msg, vim.inspect(v))
    else
      table.insert(msg, v)
    end
  end
  dbg(table.concat(msg, " "))
end

local function globalize(force, quiet)
  if state.globalized then
    return _G
  end
  force = force or false
  local mapFuncs = {}
  for _, mode in ipairs {'', 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't'} do
    local m = mode .. 'map'
    local n = mode .. 'noremap'
    mapFuncs[m] = mapx[m]
    mapFuncs[n] = mapx[n]
  end
  mapFuncs.mapbang = mapx.mapbang
  mapFuncs.noremapbang = mapx.noremapbang
  for k, v in pairs(mapFuncs) do
    if _G[k] ~= nil then
      local msg = 'overwriting key "' .. k .. '" in global scope'
      if force then
        if not quiet then
          print('mapx.global: warning: ' .. msg .. ' {force = true}')
        end
      else
        error('mapx.global: not' .. msg)
      end
    end
    _G[k] = v
  end
  return _G
end

local function try_require(pkg)
  return pcall(function()
    return require(pkg)
  end)
end

-- merge 2 or more tables non-recursively
local function merge(...)
  local res = {}
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    if type(arg) == 'table' then
      for k, v in pairs(arg) do
        if type(k) == "number" then
          table.insert(res, v)
        else
          res[k] = v
        end
      end
    else
      table.insert(res, arg)
    end
  end
  return res
end

local function export()
  return merge(mapx, mapopts)
end

-- Configure mapx
function mapx.setup(config)
  if state.setup then
    return mapx
  end
  state.config = merge(state.config, config or {})
  if state.config.whichkey then
    local ok, wk = try_require('which-key')
    if not ok then
      error('mapx.setup: config.whichkey == true but module "which-key" not found')
    end
    state.whichkey = wk
  end
  if state.config.global then
    globalize(state.config.global == "force", state.config.quiet or false)
    state.globalized = true
  end
  state.setup = true
  return export()
end

-- Deprecated!
function mapx.globalize()
  error("mapx.globalize() has been deprecated; use mapx.setup({ global = true })")
end

-- Extract a WhichKey label which is either:
-- - a key 'label'
-- - a string which can occur at the end of the integer-keyed opts
-- Returns the label and a new opts table with the label removed.
-- If WhichKey isn't enabled, returns nil and the original opts table.
local function extractLabel(opts)
  local _opts = merge({}, opts)
  local label
  if _opts.label ~= nil then
    label = _opts.label
    _opts.label = nil
    return label, _opts
  end
  if _opts[#_opts] ~= nil and mapopts[_opts[#_opts]] == nil then
    label = _opts[#_opts]
    table.remove(_opts, #_opts)
    return label, _opts
  end
  return nil, _opts
end

-- Expands string-based options like "buffer", "silent", "expr" to their
-- table-based representation. Returns a new opts table with this expansion
-- applied.
local function expandStringOpts(opts)
  local res = {}
  for k, v in pairs(opts) do
    if type(k) == "number" then
      if type(v) == 'string' and mapopts[v] ~= nil then
        res[v] = true
      else
        table.insert(res, v)
      end
    else
      res[k] = v
    end
  end
  return res
end

local function mapWhichKey(mode, lhs, rhs, opts, label)
  local wkopts = opts
  if mode ~= '' then
    wkopts = merge(opts, { mode = mode })
  end
  state.whichkey.register({
    [lhs] = { rhs, label }
  }, wkopts)
end

local function ftmap(fts, fn)
  if type(fts) ~= "table" then
    fts = { fts }
  end
  for _, ft in ipairs(fts) do
    if state.ftmaps[ft] == nil then
      state.ftmaps[ft] = {}
    end
    table.insert(state.ftmaps[ft], fn)
  end
end

function mapx._handleFileType(ft, ...)
  local ftmaps = state.ftmaps[ft]
  if ftmaps == nil then return end
  for _, fn in ipairs(ftmaps) do
    fn(...)
  end
end

function mapx._handleFunc(id, ...)
  local fn = state.funcs[id]
  if fn == nil then return end
  fn(...)
end

function mapx._handleVimEnter()
  vim.cmd(string.format([[
    augroup mapx_ftmap
      autocmd!
      autocmd FileType %s lua require'mapx'._handleFileType(vim.fn.expand('<amatch>'))
    augroup END
  ]], table.concat(vim.tbl_keys(state.ftmaps), ",")))
end

local function _map(mode, lhss, rhs, ...)
  local opts = merge({}, ...)
  local ft = opts.filetype or opts.ft
  if ft ~= nil then
    opts.ft = nil
    opts.filetype = nil
    opts.buffer = opts.buffer or 0
    ftmap(ft, function() _map(mode, lhss, rhs, opts) end)
    return
  end
  opts = expandStringOpts(opts)
  local label
  if state.whichkey ~= nil then
    label, opts = extractLabel(opts)
  end
  if opts.buffer == true then
    opts.buffer = 0
  end
  if type(lhss) ~= 'table' then
    lhss = {lhss}
  end
  if type(rhs) == 'function' then
    table.insert(state.funcs, rhs)
    local luaexpr = "require'mapx'._handleFunc(" .. #state.funcs .. ", vim.v.count)"
    if opts.expr then
      rhs = 'luaeval("' .. luaexpr .. '")'
    else
      rhs = "<Cmd>lua " .. luaexpr .. "<Cr>"
    end
  end
  for _, lhs in ipairs(lhss) do
    if label ~= nil then
      dbgi("_map whichkey", {mode=mode, lhs=lhs, rhs=rhs, opts=opts, label=label})
      mapWhichKey(mode, lhs, rhs, opts, label)
    elseif opts.buffer ~= nil then
      local b = 0
      if type(opts.buffer) ~= 'boolean' then
        b = opts.buffer
      end
      opts.buffer = nil
      dbgi("_map buffer",{b=b, mode=mode, lhs=lhs, rhs=rhs, opts=opts})
      vim.api.nvim_buf_set_keymap(b, mode, lhs, rhs, opts)
    else
      dbgi("_map",{mode=mode, lhs=lhs, rhs=rhs, opts=opts})
      vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
    end
  end
end

-- Create a Normal, Visual, Select, and Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.map(lhs, rhs, ...) return _map('', lhs, rhs, ...) end

-- Create a Normal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.nmap(lhs, rhs, ...) return _map('n', lhs, rhs, ...) end

-- Create a Normal and Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.mapbang(lhs, rhs, ...) return _map('!', lhs, rhs, ...) end

-- Create a Visual and Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.vmap(lhs, rhs, ...) return _map('v', lhs, rhs, ...) end

-- Create a Visual mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.xmap(lhs, rhs, ...) return _map('x', lhs, rhs, ...) end

-- Create a Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.smap(lhs, rhs, ...) return _map('s', lhs, rhs, ...) end

-- Create an Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.omap(lhs, rhs, ...) return _map('o', lhs, rhs, ...) end

-- Create an Insert mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.imap(lhs, rhs, ...) return _map('i', lhs, rhs, ...) end

-- Create an Insert, Command, and Lang-arg mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.lmap(lhs, rhs, ...) return _map('l', lhs, rhs, ...) end

-- Create a Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.cmap(lhs, rhs, ...) return _map('c', lhs, rhs, ...) end

-- Create a Terminal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.tmap(lhs, rhs, ...) return _map('t', lhs, rhs, ...) end

-- Create a non-recursive Normal, Visual, Select, and Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.noremap(lhs, rhs, ...) return _map('', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Normal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.nnoremap(lhs, rhs, ...) return _map('n', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Normal and Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.noremapbang(lhs, rhs, ...) return _map('!', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Visual and Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.vnoremap(lhs, rhs, ...) return _map('v', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Visual mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.xnoremap(lhs, rhs, ...) return _map('x', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.snoremap(lhs, rhs, ...) return _map('s', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.onoremap(lhs, rhs, ...) return _map('o', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Insert mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.inoremap(lhs, rhs, ...) return _map('i', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Insert, Command, and Lang-arg mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.lnoremap(lhs, rhs, ...) return _map('l', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.cnoremap(lhs, rhs, ...) return _map('c', lhs, rhs, { noremap = true }, ...) end

-- Create a non-recursive Terminal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.tnoremap(lhs, rhs, ...) return _map('t', lhs, rhs, { noremap = true }, ...) end

return export()
