# screensaver.nvim

A tiny Neovim screensaver plugin. If you stay idle for 60 seconds, it enters a screensaver mode with a random animation. Any key or activity exits the screensaver.

## Features
- Idle detection (default 60s)
- Random animations (bounce/matrix/sine)
- Auto-exit on any input or activity

## Install
Use your plugin manager.

### lazy.nvim
```lua
{
  "yourname/screensaver.nvim",
  config = function()
    require("screensaver").setup({
      idle_ms = 60 * 1000,
      frame_ms = 80,
      animations = { "bounce", "matrix", "sine" },
    })
  end,
}
```

## Commands
- `:ScreensaverStart`
- `:ScreensaverStop`
- `:ScreensaverToggle`
- `:ScreensaverDisable`

## Options
```lua
require("screensaver").setup({
  idle_ms = 60 * 1000,
  frame_ms = 80,
  enabled = true,
  animations = { "bounce", "matrix", "sine" },
  winblend = 0,
})
```

## Notes
- The screensaver uses a floating window and a scratch buffer.
- It exits on any key or activity (cursor move, insert, text change, etc.).
