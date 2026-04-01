return {
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
        q = "close",
        ["<C-q>"] = "close",
        ["<Esc><Esc>"] = "normal_mode",
      },
    },
  },
}
