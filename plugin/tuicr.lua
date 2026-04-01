if vim.g.loaded_tuicr_nvim == 1 then
  return
end
vim.g.loaded_tuicr_nvim = 1

local tuicr = require("tuicr")

vim.api.nvim_create_user_command("Tuicr", function(command_opts)
  local args = vim.deepcopy(command_opts.fargs)
  tuicr.open({ extra_args = args })
end, {
  nargs = "*",
  desc = "Open tuicr in a Neovim terminal",
})

vim.api.nvim_create_user_command("TuicrToggle", function(command_opts)
  local args = vim.deepcopy(command_opts.fargs)
  tuicr.toggle({ extra_args = args })
end, {
  nargs = "*",
  desc = "Toggle tuicr terminal window",
})
