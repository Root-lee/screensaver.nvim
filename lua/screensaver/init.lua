local M = {}
local utils = require("screensaver.utils")
local animations_module = require("screensaver.animations")

local uv = vim.loop

local default_config = {
  idle_ms = 60 * 1000,
  frame_ms = 80,
  auto_start = true,
  disable_on_focus_lost = true,
  exit_key = "<Esc>",
  animations = animations_module.get_all_names(),
  winblend = 0,
  -- Custom terminal commands for ASCII art screensavers
  -- Example:
  custom_commands = {
    -- asciiquarium = "asciiquarium -t",
  },
}

local state = {
  config = vim.deepcopy(default_config),
  idle_timer = nil,
  anim_timer = nil,
  active = false,
  buf = nil,
  win = nil,
  last_win = nil,
  tick = 0,
  animation = nil,
  anim_state = nil,
  grid = nil, -- Add grid to state
  ns = vim.api.nvim_create_namespace("screensaver"), -- Namespace for highlights
  on_key_ns = vim.api.nvim_create_namespace("screensaver-onkey"),
  augroup = vim.api.nvim_create_augroup("Screensaver", { clear = true }),
  autocmds_set = false,
  launching = false,
  rendering = false,
}

local function set_win_option(win, name, value)
  local ok = pcall(vim.api.nvim_set_option_value, name, value, { win = win })
  if not ok then
    pcall(vim.api.nvim_win_set_option, win, name, value)
  end
end

local function ui_size()
  local ui = vim.api.nvim_list_uis()[1]
  if not ui then
    return vim.o.columns, vim.o.lines
  end
  return ui.width, ui.height
end

local function pick_animation(name)
  -- First check if it's a custom command
  if name and state.config.custom_commands[name] then
    return name, {
      fps = 0,
      terminal_cmd = state.config.custom_commands[name],
      is_custom = true,
      init = function(grid)
        return { terminal_started = false }
      end,
      update = function(grid, state)
        return false
      end,
    }
  end

  -- Then check built-in animations
  if name and animations_module.get_animation(name) then
    return name, animations_module.get_animation(name)
  end

  -- If a specific name was requested but not found, return nil
  if name then
    return nil, nil
  end

  -- Pick random from available animations (including custom ones)
  local list = state.config.animations
  local custom_names = vim.tbl_keys(state.config.custom_commands)
  local all_names = vim.list_extend(vim.deepcopy(list), custom_names)

  if #all_names == 0 then
    return nil, nil
  end

  local picked = all_names[math.random(1, #all_names)]

  -- Check if it's a custom command
  if state.config.custom_commands[picked] then
    return picked, {
      fps = 0,
      terminal_cmd = state.config.custom_commands[picked],
      is_custom = true,
      init = function(grid)
        return { terminal_started = false }
      end,
      update = function(grid, state)
        return false
      end,
    }
  end

  return picked, animations_module.get_animation(picked)
end

local function stop_anim_timer()
  if state.anim_timer then
    state.anim_timer:stop()
    state.anim_timer:close()
    state.anim_timer = nil
  end
end

local function stop_idle_timer()
  if state.idle_timer then
    state.idle_timer:stop()
    state.idle_timer:close()
    state.idle_timer = nil
  end
end

local function render_frame()
  if not state.active or not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  state.rendering = true

  -- Check if this is a terminal-based animation
  if state.animation.fps == 0 and state.animation.terminal_cmd then
    -- Terminal-based animation, don't use grid rendering
    state.rendering = false
    return
  end

  state.animation.update(state.grid, state.anim_state)

  local lines = {}
  local highlights = {}

  local height = #state.grid
  for i = 1, height do
    local row = state.grid[i]
    local chars = {}
    local row_highlights = {}
    local col_idx = 0
    for _, cell in ipairs(row) do
      table.insert(chars, cell.char)
      if cell.hl_group and cell.hl_group ~= "" then
        local len = utils.string_byte_len(cell.char)
        table.insert(row_highlights, { group = cell.hl_group, start_col = col_idx, end_col = col_idx + len })
        col_idx = col_idx + len
      else
        col_idx = col_idx + utils.string_byte_len(cell.char)
      end
    end
    table.insert(lines, table.concat(chars, ""))
    table.insert(highlights, row_highlights)
  end

  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)

  -- 2. Highlights
  vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)
  for i, row_hls in ipairs(highlights) do
    for _, hl in ipairs(row_hls) do
      vim.api.nvim_buf_add_highlight(state.buf, state.ns, hl.group, i - 1, hl.start_col, hl.end_col)
    end
  end

  vim.cmd("redraw")
  state.rendering = false
end

local function start_animation()
  stop_anim_timer()

  -- Check if this is a terminal-based animation
  if state.animation.fps == 0 and state.animation.terminal_cmd then
    -- Terminal-based animation
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
      vim.api.nvim_buf_call(state.buf, function()
        vim.fn.termopen(state.animation.terminal_cmd)
      end)
    end
    return
  end

  local interval = state.config.frame_ms

  state.anim_timer = uv.new_timer()
  state.anim_timer:start(0, interval, function()
    vim.schedule(render_frame)
  end)
end

local function setup_on_key()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.keymap.set("n", state.config.exit_key, function()
      M.stop()
      M._on_activity()
    end, { buffer = state.buf, nowait = true, silent = true })

    local nop = function() end
    local keys = {
      "a",
      "b",
      "c",
      "d",
      "e",
      "f",
      "g",
      "h",
      "i",
      "j",
      "k",
      "l",
      "m",
      "n",
      "o",
      "p",
      "q",
      "r",
      "s",
      "t",
      "u",
      "v",
      "w",
      "x",
      "y",
      "z",
      "A",
      "B",
      "C",
      "D",
      "E",
      "F",
      "G",
      "H",
      "I",
      "J",
      "K",
      "L",
      "M",
      "N",
      "O",
      "P",
      "Q",
      "R",
      "S",
      "T",
      "U",
      "V",
      "W",
      "X",
      "Y",
      "Z",
      "0",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "`",
      "~",
      "!",
      "@",
      "#",
      "$",
      "%",
      "^",
      "&",
      "*",
      "(",
      ")",
      "-",
      "_",
      "=",
      "+",
      "[",
      "{",
      "]",
      "}",
      "\\",
      "|",
      ";",
      "'",
      '"',
      ",",
      "<",
      ".",
      ">",
      "/",
      "?",
      "<Esc>",
      "<CR>",
      "<BS>",
      "<Tab>",
      "<Up>",
      "<Down>",
      "<Left>",
      "<Right>",
      "<PageUp>",
      "<PageDown>",
      "<Home>",
      "<End>",
      "<Insert>",
      "<Delete>",
      "<C-w>",
      "<Space>",
    }

    for _, k in ipairs(keys) do
      if k ~= state.config.exit_key then
        pcall(vim.keymap.set, "n", k, nop, { buffer = state.buf, nowait = true, silent = true })
      end
    end
  end
end

local function clear_on_key()
  vim.on_key(nil, state.on_key_ns)
end

local function create_window()
  -- Check if this is a terminal-based animation (built-in or custom)
  local is_terminal = state.animation and state.animation.fps == 0 and state.animation.terminal_cmd

  local ok_buf, buf = pcall(vim.api.nvim_create_buf, is_terminal, true)
  if not ok_buf or not buf or buf == 0 then
    return false
  end
  state.buf = buf
  -- Only set buftype for non-terminal buffers (terminal buftype is set by termopen)
  if not is_terminal then
    vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
  end
  vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
  if not is_terminal then
    vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
  end
  vim.api.nvim_buf_set_option(state.buf, "filetype", is_terminal and "screensaver-terminal" or "screensaver")

  local width, height = ui_size()
  local ok_win, win = pcall(vim.api.nvim_open_win, state.buf, true, {
    relative = "editor",
    row = 0,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "none",
  })
  if not ok_win or not win or win == 0 then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
    state.buf = nil
    return false
  end
  state.win = win

  set_win_option(state.win, "winblend", state.config.winblend)
  set_win_option(state.win, "winhl", "NormalFloat:Screensaver,Normal:Screensaver")
  set_win_option(state.win, "number", false)
  set_win_option(state.win, "relativenumber", false)
  set_win_option(state.win, "cursorline", false)
  set_win_option(state.win, "signcolumn", "no")
  set_win_option(state.win, "foldcolumn", "0")
  return true
end

local function ensure_highlight()
  local ok, _ = pcall(vim.api.nvim_get_hl, 0, { name = "Screensaver" })
  if ok then
    return
  end

  vim.api.nvim_set_hl(0, "Screensaver", {
    fg = 0x00ff7f,
    bg = 0x000000,
    bold = true,
    ctermfg = 48,
    ctermbg = 0,
  })
end

function M.start(anim_name)
  if state.active then
    return
  end
  if vim.fn.mode() == "c" then
    return
  end

  -- Pick animation first to determine if we need to capture grid
  local name, anim = pick_animation(anim_name)
  if not anim then
    vim.notify("screensaver.nvim: No animation available. Please configure animations.", vim.log.levels.ERROR)
    return
  end

  ensure_highlight()
  state.active = true
  state.last_win = vim.api.nvim_get_current_win()

  state.animation = anim

  -- Only capture grid for non-terminal animations
  if not (anim.fps == 0 and anim.terminal_cmd) then
    state.grid = utils.snapshot_window(state.last_win)
    state.anim_state = anim.init(state.grid)
  else
    -- Create a minimal grid for terminal animations (not used for rendering)
    local width, height = ui_size()
    state.grid = {}
    for _ = 1, height do
      local row = {}
      for _ = 1, width do
        table.insert(row, { char = " ", hl_group = "" })
      end
      table.insert(state.grid, row)
    end
    state.anim_state = anim.init(state.grid)
  end

  state.tick = 0

  state.launching = true
  local ok_win = create_window()

  if not ok_win then
    state.active = false
    state.launching = false
    return
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
    -- Initial render will populate buffer
    vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
  end

  render_frame()
  start_animation()
  setup_on_key()

  vim.schedule(function()
    state.launching = false
  end)
end

function M.stop()
  if not state.active then
    M._on_activity()
    return
  end

  state.active = false
  clear_on_key()
  stop_anim_timer()

  vim.schedule(function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    state.buf = nil
    state.grid = nil

    if state.last_win and vim.api.nvim_win_is_valid(state.last_win) then
      pcall(vim.api.nvim_set_current_win, state.last_win)
    end
    state.last_win = nil

    M._on_activity()
  end)
end

function M._on_activity()
  if state.active then
    return
  end

  if not state.config.auto_start then
    if state.idle_timer then
      state.idle_timer:stop()
    end
    return
  end

  if not state.idle_timer then
    state.idle_timer = uv.new_timer()
  end
  state.idle_timer:stop()
  state.idle_timer:start(state.config.idle_ms, 0, function()
    vim.schedule(function()
      M.start()
    end)
  end)
end

local function setup_autocmds()
  if state.autocmds_set then
    return
  end

  local events = {
    "CursorMoved",
    "CursorMovedI",
    "InsertEnter",
    "InsertCharPre",
    "TextChanged",
    "TextChangedI",
    "BufEnter",
    "WinEnter",
    "CmdlineEnter",
    "CmdlineChanged",
    "FocusGained",
    "VimResized",
  }

  if vim.fn.exists("##KeyInput") == 1 then
    table.insert(events, "KeyInput")
  end

  vim.api.nvim_create_autocmd("FocusLost", {
    group = state.augroup,
    callback = function()
      if state.config.disable_on_focus_lost then
        if state.idle_timer then
          state.idle_timer:stop()
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd(events, {
    group = state.augroup,
    callback = function(args)
      if state.launching or state.rendering then
        return
      end

      if state.active and args.event == "WinEnter" then
        if state.win and not vim.api.nvim_win_is_valid(state.win) then
          M.stop()
          return
        end
      end

      if args.event == "CmdlineEnter" then
        M._on_activity()
        return
      end

      -- Screensaver rendering modifies buffer (TextChanged).
      if args.buf and args.buf == state.buf then
        local event = vim.v.event.event
        if event == "TextChanged" or event == "TextChangedI" or event == "BufEnter" then
          return
        end
      end

      if state.active then
        -- Enforce focus in screensaver window if user tries to switch away
        if args.event == "WinEnter" or args.event == "BufEnter" then
          if state.win and vim.api.nvim_win_is_valid(state.win) then
            local cur_win = vim.api.nvim_get_current_win()
            if cur_win ~= state.win then
              vim.schedule(function()
                if state.active and vim.api.nvim_win_is_valid(state.win) then
                  vim.api.nvim_set_current_win(state.win)
                end
              end)
            end
          end
        end

        if vim.v.event and vim.v.event.event == "VimResized" then
          vim.schedule(function()
            if state.win and vim.api.nvim_win_is_valid(state.win) then
              local width, height = ui_size()
              vim.api.nvim_win_set_config(state.win, {
                relative = "editor",
                row = 0,
                col = 0,
                width = width,
                height = height,
              })
            end
          end)
        end

        -- Do not stop screensaver on generic activity
        return
      end

      M._on_activity()
    end,
  })

  state.autocmds_set = true
end

function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})

  math.randomseed(os.time())

  setup_autocmds()

  M._on_activity()
end

function M.toggle()
  if state.active then
    M.stop()
  else
    M.start()
  end
end

return M
