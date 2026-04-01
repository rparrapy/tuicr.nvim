local M = {}

local defaults = {
  bin = "tuicr",
  auto_insert = true,
  close_on_exit = false,
  close_strategy = "clip_then_quit",
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
    style = "float",
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
}

local state = {
  options = vim.deepcopy(defaults),
}

function M.defaults()
  return defaults
end

function M.get()
  return state.options
end

function M.set(opts)
  state.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  return state.options
end

return M
