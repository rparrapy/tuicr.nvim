local M = {}

local function health()
  return vim.health or require("health")
end

function M.check()
  local h = health()
  local config = require("tuicr.config").get()

  h.start("tuicr.nvim")

  if vim.fn.has("nvim-0.9") == 1 then
    h.ok("Neovim 0.9+ detected")
  else
    h.error("Neovim 0.9+ is required")
  end

  if vim.fn.executable(config.bin) == 1 then
    h.ok(string.format("Found tuicr binary: %s", vim.fn.exepath(config.bin)))
  else
    h.error(string.format("Could not find executable %q in $PATH", config.bin), {
      "Install tuicr: brew install agavra/tap/tuicr",
      "Or: cargo install tuicr",
      "Or configure a custom path with require('tuicr').setup({ bin = '/path/to/tuicr' })",
    })
  end

  local cwd = config.cwd or vim.uv.cwd()
  local marker = vim.fs.find({ ".git", ".jj", ".hg" }, { path = cwd, upward = true })[1]

  if marker then
    h.ok(string.format("Repository marker detected: %s", marker))
  else
    h.warn(string.format("No .git/.jj/.hg marker found from %s", cwd), {
      "tuicr works best when launched from inside a repository",
      "You can override the working directory with require('tuicr').setup({ cwd = '/path/to/repo' })",
    })
  end
end

return M
