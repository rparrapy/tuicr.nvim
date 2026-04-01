# tuicr.nvim

A small [lazy.nvim](https://github.com/folke/lazy.nvim) plugin that runs [tuicr](https://github.com/agavra/tuicr) inside Neovim.

## Features

- Opens `tuicr` in a floating window, split, vsplit, or tab
- Works well with LazyVim / lazy.nvim
- Detects the current repo root from `.git`, `.jj`, or `.hg`
- Supports passing raw `tuicr` CLI arguments
- Configurable terminal keymaps for close / leave-terminal-mode actions
- Optional review export-to-clipboard when closing from the wrapper
- Includes `:checkhealth tuicr` integration
- Simple Lua API and `:Tuicr` / `:TuicrToggle` commands

## Requirements

- Neovim 0.9+
- `tuicr` installed and available on `$PATH`

Install `tuicr` with one of:

```bash
brew install agavra/tap/tuicr
# or
cargo install tuicr
```

## Installation

### lazy.nvim / LazyVim

```lua
{
  "rparrapy/tuicr.nvim",
  cmd = { "Tuicr", "TuicrToggle" },
  keys = {
    {
      "<leader>gr",
      function()
        require("tuicr").toggle()
      end,
      desc = "Review changes with tuicr",
    },
    {
      "<leader>gR",
      function()
        require("tuicr").open({ extra_args = { "-r", "HEAD~1..HEAD" } })
      end,
      desc = "Review last commit with tuicr",
    },
  },
  opts = {
    close_on_exit = true,
    export_on_close = true,
    force_close_timeout_ms = nil,
    win = {
      style = "float",
      border = "rounded",
      width = 0.95,
      height = 0.95,
      winblend = 0,
      title = " tuicr ",
      title_pos = "center",
    },
    keymaps = {
      q = { action = "close", mode = "n" },
      ["<C-q>"] = { action = "close", mode = { "n", "t" } },
      ["<Esc><Esc>"] = { action = "normal_mode", mode = "t" },
    },
  },
}
```

A ready-to-copy example also lives at `examples/lazy.lua`.

## Commands

```vim
:Tuicr
:Tuicr --theme onedark
:Tuicr -r HEAD~3..HEAD
:TuicrToggle
```

Everything after `:Tuicr` is forwarded to the `tuicr` binary.

## Configuration

```lua
require("tuicr").setup({
  bin = "tuicr",
  auto_insert = true,
  close_on_exit = false,
  export_on_close = true,
  force_close_timeout_ms = nil,
  cwd = nil,
  args = {},
  env = {},
  keymaps = {
    q = { action = "close", mode = "n" },
    ["<C-q>"] = { action = "close", mode = { "n", "t" } },
    ["<Esc><Esc>"] = { action = "normal_mode", mode = "t" },
  },
  win = {
    style = "float", -- float | split | vsplit | tab
    border = "rounded",
    width = 0.9,
    height = 0.9,
    row = 0.5,
    col = 0.5,
    split = "botright 15split",
    vsplit = "botright vsplit",
    winblend = 0,
    title = " tuicr ",
    title_pos = "center",
  },
})
```

## API

```lua
require("tuicr").setup(opts)
require("tuicr").open({ extra_args = { "-r", "HEAD~2..HEAD" } })
require("tuicr").toggle()
require("tuicr").close()
require("tuicr").is_open()
```

## Health check

```vim
:checkhealth tuicr
```

This verifies:
- Neovim version
- `tuicr` executable availability
- whether you're currently inside a supported repository

## Notes

- `q` closes the wrapper by default only in normal mode, so it won't hijack `tuicr`'s own `q` inside terminal mode
- `<C-q>` closes from normal or terminal mode
- Closing through the wrapper runs `:clip` and then `:x` by default; disable with `export_on_close = false`
- The plugin now waits for `tuicr` to finish its own quit flow, including confirmation dialogs
- If you really want a forced fallback kill, set `force_close_timeout_ms = 1500` (or another timeout)
- In terminal mode, use `<Esc><Esc>` to leave terminal insert mode
- If you want `tuicr` in a split instead of a float, set `win.style = "split"` or `"vsplit"`
