it('converts Neovim map API functions to mapx functions', function()
  local convert = require('mapx.convert.lua').setup {
    out = 'capture',
    passthrough = false,
  }
  local expected = vim.trim [[
local mapx = require'mapx'.setup{}
mapx.nnoremap('<leader>xx', '<cmd>Trouble<cr>', 'silent')
mapx.nnoremap('<leader>xw', '<cmd>Trouble lsp_workspace_diagnostics<cr>', 'silent')
mapx.nnoremap('<leader>xd', '<cmd>Trouble lsp_document_diagnostics<cr>', 'silent')
mapx.nnoremap('<leader>xl', '<cmd>Trouble loclist<cr>', 'silent')
mapx.nnoremap('<leader>xq', '<cmd>Trouble quickfix<cr>', 'silent')
mapx.nnoremap('gR', '<cmd>Trouble lsp_references<cr>', 'silent')
mapx.nnoremap('gR', '<cmd>Trouble lsp_references<cr>', 'buffer', 'silent')
  ]]
  loadTestData 'convert'
  local result = table.concat(convert.captured, '\n')
  expect.equal(expected, result)
end)
