local config = require("tuicr.config")

local M = {
  state = {
    buf = nil,
    win = nil,
    job = nil,
    tab = nil,
    closing = false,
  },
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "tuicr.nvim" })
end

local function normalize_ratio(value, fallback)
  if type(value) ~= "number" then
    return fallback
  end

  if value > 0 and value <= 1 then
    return value
  end

  return fallback
end

local function resolve_cwd(opts)
  if opts.cwd and opts.cwd ~= "" then
    return vim.fn.fnamemodify(opts.cwd, ":p")
  end

  local markers = { ".git", ".jj", ".hg" }
  local start = vim.api.nvim_buf_get_name(0)
  start = start ~= "" and vim.fs.dirname(start) or vim.uv.cwd()

  local root = vim.fs.dirname(vim.fs.find(markers, {
    path = start,
    upward = true,
    stop = vim.loop.os_homedir(),
  })[1] or "")

  if root and root ~= "" then
    return root
  end

  return vim.uv.cwd()
end

local function build_cmd(opts, extra_args)
  local cmd = { opts.bin }

  vim.list_extend(cmd, opts.args or {})
  vim.list_extend(cmd, extra_args or {})

  return cmd
end

local function valid_window()
  return M.state.win ~= nil and vim.api.nvim_win_is_valid(M.state.win)
end

local function valid_buffer()
  return M.state.buf ~= nil and vim.api.nvim_buf_is_valid(M.state.buf)
end

local function cleanup_window(keep_buf)
  if valid_window() then
    pcall(vim.api.nvim_win_close, M.state.win, true)
  end

  if not keep_buf and valid_buffer() then
    pcall(vim.api.nvim_buf_delete, M.state.buf, { force = true })
  end

  M.state.win = nil
  if not keep_buf then
    M.state.buf = nil
  end
end

local function should_notify_exit(code)
  if code == 0 then
    return false
  end

  if M.state.closing and (code == 129 or code == 143) then
    return false
  end

  return true
end

local function on_exit(_, code)
  vim.schedule(function()
    M.state.job = nil

    if should_notify_exit(code) then
      notify(string.format("tuicr exited with code %d", code), vim.log.levels.WARN)
    end

    if M.state.closing or config.get().close_on_exit then
      cleanup_window(false)
    end

    M.state.closing = false
  end)
end

local function create_float(buf, win_opts)
  local width = math.floor(vim.o.columns * normalize_ratio(win_opts.width, 0.9))
  local height = math.floor(vim.o.lines * normalize_ratio(win_opts.height, 0.9))
  local row = math.floor((vim.o.lines - height) * normalize_ratio(win_opts.row, 0.5))
  local col = math.floor((vim.o.columns - width) * normalize_ratio(win_opts.col, 0.5))

  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = win_opts.border or "rounded",
    width = math.max(width, 20),
    height = math.max(height, 5),
    row = math.max(row, 0),
    col = math.max(col, 0),
    title = win_opts.title,
    title_pos = win_opts.title_pos or "center",
  })
end

local function create_window(buf, win_opts)
  local style = win_opts.style or "float"

  if style == "tab" then
    vim.cmd("tabnew")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    M.state.tab = vim.api.nvim_get_current_tabpage()
    return win
  end

  if style == "split" then
    vim.cmd(win_opts.split or "botright 15split")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    return win
  end

  if style == "vsplit" then
    vim.cmd(win_opts.vsplit or "botright vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    return win
  end

  return create_float(buf, win_opts)
end

local function apply_window_options(win, buf, win_opts)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].statuscolumn = ""
  vim.wo[win].spell = false
  vim.wo[win].wrap = false
  vim.wo[win].winfixbuf = true
  vim.wo[win].winhighlight = win_opts.winhighlight or "Normal:Normal,NormalFloat:NormalFloat,FloatBorder:FloatBorder"

  if win_opts.style == "float" then
    vim.wo[win].winblend = tonumber(win_opts.winblend) or 0
  end

  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
end

local function normalize_keymap(mapping)
  if type(mapping) == "string" then
    return { action = mapping, mode = { "n", "t" } }
  end

  if type(mapping) == "function" then
    return { action = mapping, mode = { "n", "t" } }
  end

  if type(mapping) == "table" then
    local mode = mapping.mode or { "n", "t" }
    return {
      action = mapping.action or mapping[1],
      mode = mode,
    }
  end
end

local function set_terminal_keymaps(buf, keymaps)
  for lhs, raw_mapping in pairs(keymaps or {}) do
    local mapping = normalize_keymap(raw_mapping)

    if mapping then
      if mapping.action == "normal_mode" then
        vim.keymap.set(mapping.mode, lhs, [[<C-\\><C-n>]], {
          buffer = buf,
          silent = true,
          desc = "Leave terminal mode",
        })
      elseif mapping.action == "close" then
        vim.keymap.set(mapping.mode, lhs, function()
          M.close()
        end, {
          buffer = buf,
          silent = true,
          nowait = true,
          desc = "Close tuicr window",
        })
      elseif type(mapping.action) == "function" then
        vim.keymap.set(mapping.mode, lhs, mapping.action, {
          buffer = buf,
          silent = true,
          nowait = true,
          desc = "tuicr custom keymap",
        })
      end
    end
  end
end

function M.is_open()
  return valid_window()
end

local function close_sequence(opts)
  if opts.export_on_close then
    return ":clip\r:x\r"
  end

  return ":x\r"
end

local function schedule_force_close(timeout_ms)
  local timeout = tonumber(timeout_ms)
  if not timeout or timeout <= 0 then
    return
  end

  vim.defer_fn(function()
    if M.state.job then
      pcall(vim.fn.jobstop, M.state.job)
    end
  end, timeout)
end

function M.close(force)
  local opts = config.get()

  if not M.state.job then
    cleanup_window(false)
    return
  end

  M.state.closing = true

  if force then
    pcall(vim.fn.jobstop, M.state.job)
    return
  end

  pcall(vim.fn.chansend, M.state.job, close_sequence(opts))
  schedule_force_close(opts.force_close_timeout_ms)
end

function M.open(extra)
  local opts = vim.tbl_deep_extend("force", config.get(), extra or {})

  if vim.fn.executable(opts.bin) ~= 1 then
    notify(string.format("%q is not executable. Install tuicr first.", opts.bin), vim.log.levels.ERROR)
    return
  end

  if M.is_open() then
    vim.api.nvim_set_current_win(M.state.win)
    if opts.auto_insert then
      vim.cmd("startinsert")
    end
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "tuicr"

  local win = create_window(buf, opts.win or {})
  M.state.buf = buf
  M.state.win = win

  apply_window_options(win, buf, opts.win or {})

  local cmd = build_cmd(opts, opts.extra_args)
  local cwd = resolve_cwd(opts)
  local env = vim.tbl_extend("force", vim.fn.environ(), opts.env or {})

  vim.api.nvim_buf_set_name(buf, "tuicr://" .. cwd)
  set_terminal_keymaps(buf, opts.keymaps)

  M.state.job = vim.fn.termopen(cmd, {
    cwd = cwd,
    env = env,
    on_exit = on_exit,
  })

  if M.state.job <= 0 then
    notify("failed to start tuicr", vim.log.levels.ERROR)
    cleanup_window(false)
    return
  end

  if opts.auto_insert then
    vim.cmd("startinsert")
  end
end

function M.toggle(extra)
  if M.is_open() then
    M.close()
    return
  end

  M.open(extra)
end

function M.setup(opts)
  config.set(opts)
end

return M
