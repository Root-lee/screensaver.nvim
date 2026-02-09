local M = {}

local uv = vim.loop

local default_config = {
  idle_ms = 60 * 1000,
  frame_ms = 80,
  enabled = true,
  animations = { "bounce", "matrix", "sine" },
  winblend = 0,
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
  on_key_ns = vim.api.nvim_create_namespace("screensaver-onkey"),
  augroup = vim.api.nvim_create_augroup("Screensaver", { clear = true }),
  autocmds_set = false,
  launching = false,
  rendering = false,
}

local animations = {}

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

local function blank_lines(width, height)
  local line = string.rep(" ", width)
  local lines = {}
  for _ = 1, height do
    lines[#lines + 1] = line
  end
  return lines
end

animations.bounce = {
  init = function(width, height)
    return {
      x = math.floor(width / 2),
      y = math.floor(height / 2),
      dx = 1,
      dy = 1,
      ch = "o",
    }
  end,
  render = function(st, width, height)
    local lines = blank_lines(width, height)
    local x = math.max(1, math.min(width, st.x))
    local y = math.max(1, math.min(height, st.y))
    local line = lines[y]
    lines[y] = line:sub(1, x - 1) .. st.ch .. line:sub(x + 1)

    st.x = st.x + st.dx
    st.y = st.y + st.dy
    if st.x <= 1 or st.x >= width then
      st.dx = -st.dx
    end
    if st.y <= 1 or st.y >= height then
      st.dy = -st.dy
    end

    return lines
  end,
}

animations.matrix = {
  init = function(width, height)
    local cols = {}
    for i = 1, width do
      cols[i] = { y = math.random(height), speed = math.random(1, 3) }
    end
    return { cols = cols }
  end,
  render = function(st, width, height)
    local lines = blank_lines(width, height)
    for x = 1, width do
      local col = st.cols[x]
      local y = col.y
      local line = lines[y]
      lines[y] = line:sub(1, x - 1) .. string.char(math.random(33, 126)) .. line:sub(x + 1)
      col.y = col.y + col.speed
      if col.y > height then
        col.y = 1
        col.speed = math.random(1, 3)
      end
    end
    return lines
  end,
}

animations.sine = {
  init = function(width, height)
    return { phase = 0 }
  end,
  render = function(st, width, height)
    local lines = blank_lines(width, height)
    local mid = math.floor(height / 2)
    for x = 1, width do
      local y = math.floor(mid + math.sin((x / width) * math.pi * 2 + st.phase) * (height / 3))
      y = math.max(1, math.min(height, y))
      local line = lines[y]
      lines[y] = line:sub(1, x - 1) .. "*" .. line:sub(x + 1)
    end
    st.phase = st.phase + 0.3
    return lines
  end,
}

local function pick_animation()
  local list = state.config.animations
  local name = list[math.random(1, #list)]
  return name, animations[name]
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

  local width = vim.api.nvim_win_get_width(state.win)
  local height = vim.api.nvim_win_get_height(state.win)
  if width <= 0 or height <= 0 then
    return
  end

  local lines = state.animation.render(state.anim_state, width, height)
  if not lines or #lines == 0 then
    lines = { "screensaver active" }
  end

  state.rendering = true
  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
  vim.cmd("redraw")
  state.rendering = false
end

local function start_animation()
  stop_anim_timer()
  state.anim_timer = uv.new_timer()
  state.anim_timer:start(0, state.config.frame_ms, function()
    vim.schedule(render_frame)
  end)
end

local function setup_on_key()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.keymap.set("n", " ", function()
      M.stop()
      M._on_activity()
    end, { buffer = state.buf, nowait = true, silent = true })

    local nop = function() end
    local keys = { 
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
      "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
      "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
      "`", "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=", "+",
      "[", "{", "]", "}", "\\", "|", ";", ":", "'", "\"", ",", "<", ".", ">", "/", "?",
      "<Esc>", "<CR>", "<BS>", "<Tab>", "<Up>", "<Down>", "<Left>", "<Right>",
      "<PageUp>", "<PageDown>", "<Home>", "<End>", "<Insert>", "<Delete>",
      "<C-w>"
    }
    
    for _, k in ipairs(keys) do
      pcall(vim.keymap.set, "n", k, nop, { buffer = state.buf, nowait = true, silent = true })
    end
  end
end

local function clear_on_key()
  vim.on_key(nil, state.on_key_ns)
end

local function create_window()
  local ok_buf, buf = pcall(vim.api.nvim_create_buf, false, true)
  if not ok_buf or not buf or buf == 0 then
    return false
  end
  state.buf = buf
  vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
  vim.api.nvim_buf_set_option(state.buf, "filetype", "screensaver")

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

function M.start()
  if state.active then
    return
  end
  if vim.fn.mode() == "c" then
    return
  end

  ensure_highlight()
  state.active = true
  state.last_win = vim.api.nvim_get_current_win()

  local name, anim = pick_animation()
  state.animation = anim
  local width, height = ui_size()
  state.anim_state = anim.init(width, height)
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
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { "screensaver active" })
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
    return
  end

  state.active = false
  clear_on_key()
  stop_anim_timer()

  -- Use vim.schedule to close the window.
  -- This ensures that other autocommands triggered by the same event
  -- have a chance to run before the window/buffer is destroyed.
  vim.schedule(function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    state.buf = nil

    if state.last_win and vim.api.nvim_win_is_valid(state.last_win) then
      pcall(vim.api.nvim_set_current_win, state.last_win)
    end
    state.last_win = nil
  end)
end

function M._on_activity()
  if not state.config.enabled then
    return
  end
  if state.active then
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

  vim.api.nvim_create_autocmd(events, {
    group = state.augroup,
    callback = function(args)
      if state.launching or state.rendering then
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

  if state.config.enabled then
    M._on_activity()
  else
    stop_idle_timer()
  end
end

function M.toggle()
  if state.active then
    M.stop()
  else
    M.start()
  end
end

function M.disable()
  state.config.enabled = false
  stop_idle_timer()
  M.stop()
end

return M
