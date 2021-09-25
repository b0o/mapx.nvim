it('supports {global = true}', function()
  local convert = require('mapx.convert.lua').setup {
    out = 'capture',
    passthrough = false,
    config = { global = true },
  }
  local expected = vim.trim [[
require'mapx'.setup{
  global = true
}
nnoremap('<leader>xx', '<cmd>Trouble<cr>', 'silent')
nnoremap('<leader>xw', '<cmd>Trouble lsp_workspace_diagnostics<cr>', 'silent')
nnoremap('<leader>xd', '<cmd>Trouble lsp_document_diagnostics<cr>', 'silent')
nnoremap('<leader>xl', '<cmd>Trouble loclist<cr>', 'silent')
nnoremap('<leader>xq', '<cmd>Trouble quickfix<cr>', 'silent')
nnoremap('gR', '<cmd>Trouble lsp_references<cr>', 'silent')
nnoremap('gR', '<cmd>Trouble lsp_references<cr>', 'buffer', 'silent')
  ]]
  loadTestData 'convert'
  local result = table.concat(convert.captured, '\n')
  expect.equal(expected, result)
end)
