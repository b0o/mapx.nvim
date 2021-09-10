local M = {
  debug = false,
}

function M.warn(msg)
  vim.api.nvim_echo({{ msg, "WarningMsg" }}, true, {})
end

local function getpwin()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
   if vim.fn.win_gettype(w) == "preview" then
     return w
   end
 end
end

function M.previewAppend(lines)
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
    return false
  end
  local pbuf = vim.api.nvim_win_get_buf(pwin)
  vim.api.nvim_buf_set_option(pbuf, "modifiable", true)
  vim.api.nvim_buf_set_lines(pbuf, -1, -1, false, lines)
  vim.api.nvim_buf_set_option(pbuf, "modifiable", false)
  vim.api.nvim_win_set_cursor(pwin, {vim.api.nvim_buf_line_count(pbuf), 0})
  return true
end

-- debug writes debug messages to the preview window
function M.dbg(...)
  if not M.debug then return end
  local msg = string.format("[%s] %s\n", os.date "%H:%M:%S", table.concat({...}, " "))
  if not M.previewAppend(vim.split(msg, "\n", true)) then
    print(...)
    return
  end
end

-- debugInspect
function M.dbgi(...)
  if not M.debug then return end
  local msg = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    if type(v) == "table" or type(v) == "function" or type(v) == "thread" or type(v) == "userdata" then
      table.insert(msg, vim.inspect(v))
    else
      table.insert(msg, v)
    end
  end
  M.dbg(table.concat(msg, " "))
end

return M
