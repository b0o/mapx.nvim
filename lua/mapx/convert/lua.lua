local M = {
  config = {
    quotes = {
      { "'", "'" },
      { '"', '"' },
      { "[[", "]]" },
    },
    config = {},
    importName = "mapx",
    optStyle = "string",
    out = "preview",
    passthrough = true,
  },
  captured = {},
}

local function printLines(lines)
  print(table.concat(lines, "\n") .. "\n")
end

local function captureLines(lines)
  vim.list_extend(M.captured, lines, 1)
end

local function previewLines(lines)
  require'mapx.log'.previewAppend(lines)
end

local out

local function escapePat(str)
  return string.gsub(str, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
end

local function quote(str)
  for _, q in ipairs(M.config.quotes) do
    if string.find(str, "[" .. escapePat(q[1]) .. escapePat(q[2]) .. "]") == nil then
      return q[1] .. str .. q[2]
    end
  end
  error("Unable to quote string: " .. str)
end

local function writeImport()
  local opts = vim.tbl_extend("force", {}, M.config and M.config.config or {})
  local prefix = "local " .. M.config.importName .. " = "
  if M.config and M.config.config and M.config.config.global and M.config.optStyle ~= "var" then
    prefix = ""
  end
  out(vim.split(string.format("%srequire%s.setup%s", prefix, quote("mapx"), vim.inspect(opts)), "\n"))
end

local function convert(mode, lhs, rhs, opts)
  opts = opts or {}
  if opts.noremap then
    mode = mode .. "nore"
    opts.noremap = nil
  end
  local mapxOpts = {}
  if M.config.optStyle == "string" or M.config.optStyle == "vim" or M.config.optStyle == "var" then
    for _, o in ipairs { "buffer", "nowait", "silent", "script", "expr", "unique" } do
      if opts[o] then
        if o == "buffer" and opts[o] ~= 0 then
          goto continue
        end
        local s
        if M.config.optStyle == "vim" then
          s = quote("<" .. o .. ">")
        elseif M.config.optStyle == "var" then
          s = M.config.importName .. "." .. o
        else
          s = quote(o)
        end
        table.insert(mapxOpts, s)
        opts[o] = nil
      end
      ::continue::
    end
  end

  local mapxOptsStr = table.concat(mapxOpts, ", ")
  local restOptsStr = vim.inspect(opts, { newline = "", indent = "" })
  restOptsStr = restOptsStr ~= "{}" and restOptsStr or nil

  local fullOptsStr = ""
  if mapxOptsStr and mapxOptsStr ~= "" then fullOptsStr = fullOptsStr .. ", " .. mapxOptsStr end
  if restOptsStr and restOptsStr ~= "" then fullOptsStr = fullOptsStr .. ", " .. restOptsStr end

  local qualifier = ""
  if not M.config.config.global then qualifier = M.config.importName .. "." end

  local fn = "map"
  if mode == "!" then
    mode = ""
    fn = "mapbang"
  end

  local mapStr = string.format("%s%s%s(%s, %s%s)",
    qualifier, mode, fn, quote(lhs), quote(rhs),  fullOptsStr)

  out(vim.split(mapStr, "\n"))
end

local function wrapped_nvim_set_keymap(mode, lhs, rhs, opts)
  if M.config.passthrough then
    M.orig_nvim_set_keymap(mode, lhs, rhs, opts)
  end
  convert(mode, lhs, rhs, opts)
end

local function wrapped_nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  if M.config.passthrough then
    M.orig_nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
  end
  convert(mode, lhs, rhs, vim.tbl_extend("force", { buffer = buffer }, opts))
end

function M.setup(config)
  M.config = vim.tbl_extend("force", M.config, config)
  M.config.config = M.config.config or {}

  if M.config.out == "preview" then
    out = previewLines
  elseif M.config.out == "print" then
    out = printLines
  elseif M.config.out == "capture" then
    out = captureLines
  end

  M.orig_nvim_set_keymap = vim.api.nvim_set_keymap
  M.orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap

  vim.api.nvim_set_keymap = wrapped_nvim_set_keymap
  vim.api.nvim_buf_set_keymap = wrapped_nvim_buf_set_keymap

  writeImport()

  return M
end

return M
