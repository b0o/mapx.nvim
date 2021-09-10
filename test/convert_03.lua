it("supports {global = true, optStyle = 'var', importName = 'm'}", function()
  local convert = require'mapx.convert.lua'.setup({
    out = 'capture',
    passthrough = false,
    config = { global = true },
    optStyle = "var",
    importName = "m"
  })
  local expected = vim.trim([[
local m = require'mapx'.setup{
  global = true
}
nnoremap('<leader>xx', '<cmd>Trouble<cr>', m.silent)
nnoremap('<leader>xw', '<cmd>Trouble lsp_workspace_diagnostics<cr>', m.silent)
nnoremap('<leader>xd', '<cmd>Trouble lsp_document_diagnostics<cr>', m.silent)
nnoremap('<leader>xl', '<cmd>Trouble loclist<cr>', m.silent)
nnoremap('<leader>xq', '<cmd>Trouble quickfix<cr>', m.silent)
nnoremap('gR', '<cmd>Trouble lsp_references<cr>', m.silent)
nnoremap('gR', '<cmd>Trouble lsp_references<cr>', m.buffer, m.silent)
  ]])
  loadTestData("convert")
  local result = table.concat(convert.captured, "\n")
  expect.equal(expected, result)
end)
