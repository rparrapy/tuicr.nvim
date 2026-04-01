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
      export_on_close = true,
      close_fallback_ms = 1500,
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
  },
}
