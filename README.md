# mapx.lua [![version](https://img.shields.io/github/v/tag/b0o/mapx.lua?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/mapx.lua/releases) [![license: MIT](https://img.shields.io/github/license/b0o/mapx.lua?style=flat&color=green)](https://mit-license.org)

A Neovim lua plugin to make mapping more manageable.

mapx.lua provides lua helper functions that mimic vim's `:map` family of
commands. Its aim is to make configuring key maps from within lua more
ergonomic.

Before mapx:

```lua
vim.api.nvim_set_keymap("", [[<C-z>]], [[<Nop>]])
vim.api.nvim_set_keymap("!", [[<C-z>]], [[<Nop>]])

vim.api.nvim_set_keymap("n", [[j]], [[v:count ? 'j' : 'gj']], { noremap = true, expr = true })
vim.api.nvim_set_keymap("n", [[k]], [[v:count ? 'k' : 'gk']], { noremap = true, expr = true })

vim.api.nvim_set_keymap("n", [[J]], [[5j]])
vim.api.nvim_set_keymap("n", [[K]], [[5k]])

vim.api.nvim_set_keymap("i", [[<Tab>]], [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { noremap = true, silent = true, expr = true })
vim.api.nvim_set_keymap("i", [[<S-Tab>]], [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { noremap = true, silent = true, expr = true })
```

With mapx:

```lua
require'mapx'.globalize()

map([[<C-z>]], [[<Nop>]])
mapbang([[<C-z>]], [[<Nop>]])

nnoremap([[j]], [[v:count ? 'j' : 'gj']], "expr")
nnoremap([[k]], [[v:count ? 'k' : 'gk']], "expr")

nmap([[J]], [[5j]])
nmap([[K]], [[5k]])

inoremap([[<Tab>]], [[pumvisible() ? "\<C-n>" : "\<Tab>"]], "silent", "expr")
inoremap([[<S-Tab>]], [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], "silent", "expr")
```

See the [full documentation](https://github.com/b0o/mapx.lua/blob/main/doc/mapx.txt) for more information.

## Install

[Packer](https://github.com/wbthomason/packer.nvim):

```lua
use "b0o/mapx.lua"
```

## License

<!-- LICENSE -->

&copy; 2021 Maddison Hellstrom

Released under the MIT License.

<!-- /LICENSE -->
