local wk = require 'which-key'
local log = require 'mapx.log'

local dbgi = log.dbgi

local function register(maps, opts)
  opts = opts or {}
  opts.mode = opts.mode ~= '' and opts.mode or nil
  opts.buffer = opts.buffer ~= -1 and opts.buffer or nil
  opts.silent = opts.silent ~= nil and opts.silent or false
  opts.noremap = opts.noremap ~= nil and opts.noremap or false
  if opts.buffer and not vim.api.nvim_buf_is_valid(opts.buffer) then
    return
  end
  dbgi('mapx.whichkey register', { maps = maps, opts = opts })
  wk.register(maps, opts)
end

local M = {}

function M.new(opts)
  local self = vim.tbl_extend('force', {
    queueCap = 0,
    timerInterval = 150,
  }, opts or {})

  self.queue = {}
  self.queueLen = 0
  self.queueTimer = nil

  return setmetatable(self, { __index = M })
end

local function stopTimer(self)
  if not self.queueTimer then
    return
  end
  vim.loop.timer_stop(self.queueTimer)
  self.queueTimer = nil
end

local function restartTimer(self)
  stopTimer(self)
  if self.timerInterval <= 0 then
    return
  end
  self.queueTimer = vim.defer_fn(function()
    dbgi 'Mapper:bufferWhichkeyMap timer'
    self.queueTimer = nil
    self:flush()
  end, self.timerInterval)
end

function M:flush()
  dbgi('WhichKey:flush', { queue = self.queue })

  stopTimer(self)

  if vim.tbl_isempty(self.queue) then
    return
  end

  for mode, buffers in pairs(self.queue) do
    for buffer, maps in pairs(buffers) do
      register(maps, { mode = mode, buffer = buffer })
    end
  end

  self.queue = {}
  self.queueLen = 0
end

function M:map(mode, buffer, lhs, opts)
  buffer = buffer or -1
  dbgi('WhichKey:enqueue', { mode = mode, buffer = buffer, lhs = lhs, opts = opts })

  self.queue[mode] = self.queue[mode] or {}
  self.queue[mode][buffer] = self.queue[mode][buffer] or {}
  self.queue[mode][buffer][lhs] = opts
  self.queueLen = self.queueLen + 1

  if self.queueCap > 0 and self.queueLen >= self.queueCap then
    self:flush()
    return
  end

  restartTimer(self)
end

return M
