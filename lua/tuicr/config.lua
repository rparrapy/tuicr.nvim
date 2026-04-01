local M = {}

local defaults = {
  bin = "tuicr",
  auto_insert = true,
  close_on_exit = false,
  cwd = nil,
  args = {},
  env = {},
  keymaps = {
    q = "close",
    ["<C-q>"] = "close",
    ["<Esc><Esc>"] = "normal_mode",
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
