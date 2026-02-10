# ✨ screensaver.nvim

> A delightful screensaver plugin for Neovim that brings your idle terminal to life! 💤

When you stay idle for 60 seconds (default), this plugin activates a screensaver mode with random, mesmerizing animations that interact with your code.

## 🌟 Features

- 🕒 **Idle Detection**: Automatically starts after a configurable period of inactivity.
- 🎨 **Rich Animations**: Includes a variety of effects like Matrix rain, Game of Life, sliding text, and more!
- 🔒 **Safe Mode**: While active, your buffer is protected. Only pressing **Space** exits the screensaver.
- 🚀 **Interactive**: Many animations (like `game_of_life`, `scramble`) play with your existing code content!

## 📦 Install

Use your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Root-lee/screensaver.nvim",
  config = function()
    require("screensaver").setup({
      idle_ms = 60 * 1000, -- Idle time in milliseconds (1 minute)
    })
  end,
}
```

## 🎮 Animations

The plugin comes with a suite of built-in animations:

- 🟢 **matrix**: The classic digital rain effect (now with colors!).
- 🌧️ **rain**: Characters fall down like heavy rain.
- 🧬 **game_of_life**: Conway's Game of Life simulation using your code characters.
- ⬅️ **move_left** / ➡️ **move_right**: Slides your code horizontally.
- 🔀 **scramble**: Randomly shuffles characters in your buffer.
- 🔡 **random_case**: Randomly flips uppercase and lowercase letters.
- 🎾 **bounce**: A simple bouncing character (classic).
- 〰️ **sine**: A sine wave animation.

## 🛠️ Configuration

You can customize the screensaver by passing options to the `setup` function:

```lua
require("screensaver").setup({
  -- ⏱️ Time in milliseconds before the screensaver starts
  idle_ms = 60 * 1000,

  -- 🎞️ Refresh rate for animations (lower = faster/smoother)
  frame_ms = 80,

  -- ✅ Enable/Disable the plugin globally
  enabled = true,

  -- 🎬 List of enabled animations (defaults to all available)
  animations = {
    "matrix",
    "rain",
    "game_of_life",
    "move_left",
    "move_right",
    "scramble",
    "random_case",
    "bounce",
    "sine",
  },

  -- 👻 Window transparency (0-100)
  winblend = 0,
})
```

## ⌨️ Commands

| Command | Description |
|---------|-------------|
| `:ScreensaverStart` | Manually trigger the screensaver immediately |
| `:ScreensaverStop` | Stop the screensaver |
| `:ScreensaverToggle` | Toggle the screensaver on/off |
| `:ScreensaverDisable` | Completely disable the plugin (stops idle timer) |

## 📝 Notes

- **Exit**: Press **Space** to exit the screensaver and return to your code.
- **Protection**: While the screensaver is running, other keys are blocked to prevent accidental edits.
- The screensaver creates a floating window that overlays your current buffer.

---

<p align="center">
  Made with ❤️ for Neovim
</p>
