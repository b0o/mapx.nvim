## Autoconvert your Neovim-style mappings to Mapx

Mapx provides the ability to convert mappings that use Neovim's
`vim.api.nvim_set_keymap()`/`vim.api.nvim_buf_set_keymap()` functions to the
Mapx API.

To use the converter, copy your mappings (ideally without any other config)
into a new Lua file and run the [converter script](https://github.com/b0o/mapx.nvim/blob/main/scripts/convert) on it.
The conversion result will be written to stdout.

For example, if the file containing your mappings is at `/tmp/maps.lua`:

```sh
$ cat /tmp/maps.lua
vim.api.nvim_set_keymap("!", "<C-z>", "<Nop>")
vim.api.nvim_set_keymap("v", ">", ">gv", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<leader>xx", "<cmd>Trouble<cr>", {silent = true, noremap = true})
vim.api.nvim_set_keymap("n", "<leader>xw", "<cmd>Trouble lsp_workspace_diagnostics<cr>", {silent = true })
vim.api.nvim_buf_set_keymap(0, "", "gR", "<cmd>Trouble lsp_references<cr>", { noremap = true})

$ /path/to/mapx.nvim/scripts/convert /tmp/maps.lua
local mapx = require'mapx'.setup{}
mapx.mapbang('<C-z>', '<Nop>')
mapx.vnoremap('>', '>gv', 'silent')
mapx.nnoremap('<leader>xx', '<cmd>Trouble<cr>', 'silent')
mapx.nmap('<leader>xw', '<cmd>Trouble lsp_workspace_diagnostics<cr>', 'silent')
mapx.noremap('gR', '<cmd>Trouble lsp_references<cr>', 'buffer')
```

You can provide a configuration table via the `-c` flag. For example:

```sh
$ /path/to/mapx.nvim/scripts/convert -c '{ config = { global = true }, optStyle = "string" }'` /tmp/maps.lua
local mapx = require'mapx'.setup{
  global = true
}
mapbang('<C-z>', '<Nop>')
vnoremap('>', '>gv', 'silent')
nnoremap('<leader>xx', '<cmd>Trouble<cr>', 'silent')
nmap('<leader>xw', '<cmd>Trouble lsp_workspace_diagnostics<cr>', 'silent')
noremap('gR', '<cmd>Trouble lsp_references<cr>', 'buffer')
```

If you installed Mapx via Packer, the convert script is likely located at
`$HOME/.local/share/nvim/site/pack/packer/start/mapx.nvim/scripts/convert`.

Note that the output will not include any comments, formatting, or any code other
than calls to `vim.api.nvim_set_keymap()`/`vim.api.nvim_buf_set_keymap()`.

See `:help mapx-convert` for more information.

A VimL converter is planned but not yet implemented. PRs welcome :)
