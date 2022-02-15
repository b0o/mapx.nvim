# Mapx.nvim [![version](https://img.shields.io/github/v/tag/b0o/mapx.nvim?style=flat&color=yellow&label=version&sort=semver)](https://github.com/b0o/mapx.nvim/releases) [![license: MIT](https://img.shields.io/github/license/b0o/mapx.nvim?style=flat&color=green)](https://mit-license.org) [![Build Status](https://img.shields.io/github/workflow/status/b0o/mapx.nvim/test)](https://github.com/b0o/mapx.nvim/actions/workflows/test.yaml)

A Neovim Lua plugin to make mapping and commands more manageable.

Mapx.nvim is a Lua library that mimics Vim's `:map` and `:command` family of
commands.
Its aim is to make configuring key mappings and commands from within Lua more
ergonomic.

Without Mapx:

```lua
vim.api.nvim_set_keymap("n", "j", "v:count ? 'j' : 'gj'", { noremap = true, expr = true })
vim.api.nvim_set_keymap("n", "k", "v:count ? 'k' : 'gk'", { noremap = true, expr = true })

vim.api.nvim_set_keymap("n", "J", "5j", {})
vim.api.nvim_set_keymap("n", "K", "5k", {})

vim.api.nvim_set_keymap("i", "<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { noremap = true, silent = true, expr = true })
vim.api.nvim_set_keymap("i", "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { noremap = true, silent = true, expr = true })

vim.api.nvim_set_keymap("", "<M-/>", ":Commentary<Cr>", { silent = true })

vim.cmd [[command -nargs=0 LspDiag lua vim.lsp.diagnostic.set_loclist()]]
```

With Mapx:

```lua
require'mapx'.setup{ global = true }

nnoremap("j", "v:count ? 'j' : 'gj'", "expr")
nnoremap("k", "v:count ? 'k' : 'gk'", "expr")

nmap("J", "5j")
nmap("K", "5k")

inoremap("<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]], "silent", "expr")
inoremap("<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], "silent", "expr")

map("<M-/>", ":Commentary<Cr>", "silent")

cmd("LspDiag", function() vim.lsp.diagnostic.set_loclist() end, {nargs = 0})
```

## Features

Create multiple mappings to the same action in one shot:

```lua
nnoremap({"<C-f><C-f>", "<C-f>f"}, ":lua require('telescope.builtin').find_files()<Cr>", "silent")
```

#### WhichKey Integration

Integrate with [which-key.nvim](https://github.com/folke/which-key.nvim) by
passing a label as the final argument:

```lua
local m = require'mapx'.setup{ global = true, whichkey = true }

nnoremap("gD", "<cmd>lua vim.lsp.buf.declaration()<Cr>", "silent", "LSP: Goto declaration")

-- Also supports setting WhichKey group names
m.nname("<leader>l", "LSP")
nnoremap("<leader>li", ":LspInfo<Cr>",    "LSP: Show LSP information")
nnoremap("<leader>lr", ":LspRestart<Cr>", "LSP: Restart LSP")
nnoremap("<leader>ls", ":LspStart<Cr>",   "LSP: Start LSP")
nnoremap("<leader>lS", ":LspStop<Cr>",    "LSP: Stop LSP")
```

#### FileType Mappings

FileType mappings will be applied only to buffers with a matching filetype.

```lua
nnoremap("<tab>",   [[:call search('\(\w\+(\w\+)\)', 's')<Cr>]],  "silent", { ft = "man" })
nnoremap("<S-tab>", [[:call search('\(\w\+(\w\+)\)', 'sb')<Cr>]], "silent", { ft = "man" })
```

#### Groups

Mappings with common options can be grouped to reduce repetition.

```lua
mapx.group("silent", { ft = "man" }, function()
  nnoremap("<tab>",   [[:call search('\(\w\+(\w\+)\)', 's')<Cr>]])
  nnoremap("<S-tab>", [[:call search('\(\w\+(\w\+)\)', 'sb')<Cr>]])
end)
```

#### Lua Function Mappings

The `{rhs}` of a mapping can be a Lua function.

```lua
map("<leader>hi", function() print("Hello!") end, "silent")

-- Expression maps work too:
nnoremap("j", function() return vim.v.count > 0 and "j" or "gj" end, "silent", "expr")
nnoremap("k", function() return vim.v.count > 0 and "k" or "gk" end, "silent", "expr")
```

#### Buffer Mappings

Mappings can be applied to the current buffer, or to a specific buffer.

```lua
-- Use the current buffer
nnoremap("<C-]>", ":call man#get_page_from_cword('horizontal', v:count)<CR>", "silent", "buffer")

-- Use a specific buffer
nnoremap("<C-]>", ":call man#get_page_from_cword('horizontal', v:count)<CR>", "silent", {
  buffer = vim.api.nvim_win_get_buf(myWindowVariable)
})
```

#### Map Options

There are various ways to specify map options:

```lua
-- Lua tables
nnoremap ("j", "v:count ? 'j' : 'gj'", { silent = true, expr = true })

-- Multiple Lua tables
nnoremap ("j", "v:count ? 'j' : 'gj'", { silent = true }, { expr = true })

-- Mapx's exported convenience variables
nnoremap ("j", "v:count ? 'j' : 'gj'", mapx.silent, mapx.expr)

-- Strings
nnoremap ("j", "v:count ? 'j' : 'gj'", "silent", "expr")

-- Vim-style strings
nnoremap ("j", "v:count ? 'j' : 'gj'", "<silent>", "<expr>")
```

#### Global Functions

Adding the Mapx map functions to the global scope is opt-in.

```lua
local mapx = require'mapx'
mapx.nmap("J", "5j")
mapx.nmap("K", "5k")
```

#### Commands

Create commands easily with the `cmd` and `cmdbang` functions. The
`cmdbang` function only differs from the `cmd` function in that it creates
a function with a bang which overwrites a previously defined function with
the same name.

```lua
cmd("LspDiag",
  function() vim.lsp.diagnostic.set_loclist() end,
  {nargs = 0})
cmdbang("LspAddFolder",
  function(opt) vim.lsp.buf.add_workspace_folder(opt.arguments[1]) end,
  {nargs = 1, complete = 'file'})
cmdbang("LspRemFolder",
  function(opt) vim.lsp.buf.remove_workspace_folder(opt.arguments[1]) end,
  {nargs = 1, complete = 'file'})
```

#### Documentation

Mapx is fully documented. See [`:help mapx`](https://github.com/b0o/mapx.nvim/blob/main/doc/mapx.txt).

#### Autoconvert your Neovim-style mappings to Mapx

Mapx provides the ability to convert mappings that use Neovim's
`vim.api.nvim_set_keymap()`/`vim.api.nvim_buf_set_keymap()` functions to the
Mapx API.

See the [conversion documentation](https://github.com/b0o/mapx.nvim/blob/main/conversion.md) for instructions.

## Install

[Packer](https://github.com/wbthomason/packer.nvim):

```lua
use "b0o/mapx.nvim"
```

## Wishlist

Mapx aims to be the most powerful way to configure key mappings. To that end,
we'd like to include the following features in future versions:

- [ ] Autocommand mappings (a generalization of FileType mappings).
- [ ] VimL conversion tool.
- [ ] [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) integration.
- [x] API for creating user commands.
- [ ] API for creating user autocommands.
- [ ] Support passing mapping mode in opts.
- [ ] Support specifying multiple modes as a string like 'nvt'.
- [x] Support specifying labels on groups which become which-key group names.
- [x] Support progressively building up maps with groups, like:

  ```lua
  mapx.group({ prefix = "<leader>t" }, "LSP", function()
    mapx.group({ prefix = "g" }, "Goto", function()
      nnoremap("d", "<cmd>lua vim.lsp.buf.definition()<Cr>",      "Definition")
      nnoremap("D", "<cmd>lua vim.lsp.buf.declaration()<Cr>",     "Declaration")
      nnoremap("i", "<cmd>lua vim.lsp.buf.implementation()<Cr>",  "Implementation")
      nnoremap("t", "<cmd>lua vim.lsp.buf.type_definition()<Cr>", "Type definition")
      nnoremap("r", "<cmd>lua vim.lsp.buf.references()<Cr>",      "References")
    end)
    mapx.group({ prefix = "w" }, "Workspace", function()
      nnoremap("a", "<cmd>lua vim.lsp.buf.add_workspace_folder()<Cr>",                       "Add folder")
      nnoremap("r", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<Cr>",                    "Rm folder")
      nnoremap("l", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<Cr>", "List folders")
    end)
  end)

  -- Would be equivalent to:
  mapx.nname("<leader>l", "LSP")
  mapx.nname("<leader>lg", "LSP-Goto")
  nnoremap ("<leader>lgd", "<cmd>lua vim.lsp.buf.definition()<Cr>",      "LSP-Goto: Definition")
  nnoremap ("<leader>lgD", "<cmd>lua vim.lsp.buf.declaration()<Cr>",     "LSP-Goto: Declaration")
  nnoremap ("<leader>lgi", "<cmd>lua vim.lsp.buf.implementation()<Cr>",  "LSP-Goto: Implementation")
  nnoremap ("<leader>lgt", "<cmd>lua vim.lsp.buf.type_definition()<Cr>", "LSP-Goto: Type definition")
  nnoremap ("<leader>lgr", "<cmd>lua vim.lsp.buf.references()<Cr>",      "LSP-Goto: References")
  mapx.nname("<leader>lw", "LSP-Workspace")
  nnoremap ("<leader>lwa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<Cr>",                       "LSP-Workspace: Add folder")
  nnoremap ("<leader>lwr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<Cr>",                    "LSP-Workspace: Rm folder")
  nnoremap ("<leader>lwl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<Cr>", "LSP-Workspace: List folders")
  ```

- [ ] Better test coverage
- [ ] Support setting default opts in `.setup{}`
- [ ] Benchmarks
- [ ] Performance optimization (especially WhichKey integration)

## Changelog

```
01 Nov 2021                                                             v0.2.2
   Added user command support

10 Sep 2021                                                             v0.2.1
   Renamed project to Mapx.nvim
   Added tests
   Added config auto-conversion tool
   Fixed bugs

08 Sep 2021                                                             v0.2.0
   Breaking: Deprecated config.quiet in favor of `setup({global = "force"})`
             or `setup({global = "skip"})`

08 Sep 2021                                                             v0.1.2
   Added support for assigning WhichKey group names
   Allow wrapping string opts in <angle brackets>
   Refactored code
   Bug fixes

04 Sep 2021                                                             v0.1.1
   Added `mapx.group()`
   Added debug logging with `mapx-config-debug`
   Added support for `mapx-opt-filetype` maps
   Added support for Lua functions as a map's `{rhs}`
   Added `mapx-config-quiet`
   Fixed bugs

01 Sep 2021                                                             v0.1.0
   Added `mapx.setup()`
   Added `mapx-whichkey-support`
   Breaking: Deprecated `mapx.globalize()` in favor of `setup({global = true})`

28 Aug 2021                                                             v0.0.2
  Added `mapx.globalize()`

27 Aug 2021                                                             v0.0.1
  Initial Release
```

## License

<!-- LICENSE -->

&copy; 2021 Maddison Hellstrom

Released under the MIT License.

<!-- /LICENSE -->
