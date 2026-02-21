# ✨ screensaver.nvim

> A delightful screensaver plugin for Neovim that brings your idle terminal to life! 💤

When you stay idle for 60 seconds (default), this plugin activates a screensaver mode with random, mesmerizing animations that interact with your code.

## 🌟 Features

- 🕒 **Idle Detection**: Automatically starts after a configurable period of inactivity.
- 🎨 **Rich Animations**: Includes a variety of effects like Matrix rain, Game of Life, sliding text, and more!
- 🔧 **Custom Commands**: Support for any terminal-based ASCII art (cmatrix, asciiquarium, nyancat, etc.)
- 🔒 **Safe Mode**: While active, your buffer is protected. Only pressing **Space** (configurable) exits the screensaver.
- 🚀 **Interactive**: Many animations (like `game_of_life`, `scramble`) play with your existing code content!
- ⏸️ **Focus Aware**: Pauses auto-start when Neovim loses focus (great for tmux users!).

## 📦 Install

Use your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourname/screensaver.nvim",
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
- ✨ **starfield**: A classic 3D starfield simulation.
- 🧱 **pipes**: Retro 3D pipes growing across the screen.
- 🔥 **fire**: A Doom-style fire effect.
- ❄️ **snow**: Gentle snow falling over your code.
- 🐘 **zoo**: Various animals wandering around your screen.

### Custom Terminal Commands 🖥️

You can also use any terminal-based ASCII art program as a screensaver! Some popular options:

- **asciiquarium**: An aquarium ASCII art animation
- **cmatrix**: Matrix-style digital rain
- **nyancat**: The famous rainbow cat animation
- **aafire**: Fire effect using ASCII art
- **sl**: Steam locomotive animation

See the [Custom Commands](#-custom-commands) section below for configuration details.

## 🛠️ Configuration

You can customize the screensaver by passing options to the `setup` function:

```lua
require("screensaver").setup({
  -- ⏱️ Time in milliseconds before the screensaver starts
  idle_ms = 60 * 1000,

  -- 🚀 Automatically start screensaver after idle time (set to false for manual only)
  auto_start = true,

  -- 🛡️ Disable auto-start when Neovim loses focus (e.g. switching tmux windows)
  -- Requires `set -g focus-events on` in your tmux.conf
  disable_on_focus_lost = true,

  -- ⌨️ Key to exit the screensaver
  exit_key = "<Esc>",

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
    "starfield",
    "pipes",
    "fire",
    "snow",
    "zoo",
  },

  -- 👻 Window transparency (0-100)
  winblend = 0,
})
```

### 🖥️ Custom Commands

You can add custom terminal-based ASCII art animations using the `custom_commands` option:

```lua
require("screensaver").setup({
  custom_commands = {
    -- Aquarium (requires asciiquarium installed)
    aquarium = "asciiquarium -t",

    -- Matrix-style digital rain (requires cmatrix installed)
    cmatrix = "cmatrix -s",

    -- Rainbow cat animation (requires nyancat installed)
    nyancat = "nyancat",

    -- Fire effect (requires aafire installed)
    -- Note: aafire exits after one run, so we use a loop
    aafire = "while true; do aafire; done",

    -- Steam locomotive (requires sl installed)
    -- Note: sl exits after one run, so we use a loop
    sl = "while true; do sl -aF; done",

    -- Custom figlet animation
    figlet = "watch -n 1 'echo Neovim | figlet | lolcat'",
  },

  -- Add custom command names to animations list to include them in rotation
  animations = {
    "aquarium",
    "cmatrix",
    "matrix",
    "rain",
    -- ... other animations
  },
})
```

**Tips:**
- Some commands like `sl` and `aafire` exit after running once. Wrap them in `while true; do <command>; done` to loop continuously.
- Make sure the required programs are installed on your system and available in your PATH.
- Test commands in your terminal before adding them to the configuration.

## ⌨️ Commands

| Command | Description |
|---------|-------------|
| `:ScreensaverStart [anim]` | Start screensaver immediately. Optional: specify animation name (e.g. `:ScreensaverStart rain`) |
| `:ScreensaverStop` | Stop the screensaver |
| `:ScreensaverToggle` | Toggle the screensaver on/off |

You can also use the Lua API directly:

```lua
-- Start a specific animation
:lua require("screensaver").start("matrix")
:lua require("screensaver").start("aquarium")  -- custom command

-- Stop the screensaver
:lua require("screensaver").stop()

-- Toggle on/off
:lua require("screensaver").toggle()
```

## 📝 Notes

- **Exit**: Press **`<Esc>`** (or your configured `exit_key`) to exit the screensaver and return to your code.
- **Protection**: While the screensaver is running, other keys are blocked to prevent accidental edits.
- The screensaver creates a floating window that overlays your current buffer.

### Tmux Support

If you use **tmux**, you likely don't want the screensaver starting when you've switched to another window. This plugin handles `FocusLost` events to pause the idle timer.

**Required**: Add this to your `~/.tmux.conf` or `~/.config/tmux/tmux.conf` to enable focus events:

```tmux
set -g focus-events on
```

---

## 🙏 Acknowledgments

This project was inspired by and built with reference to the following amazing projects:

- [cellular-automaton.nvim](https://github.com/Eandrju/cellular-automaton.nvim) - A plugin for creating cool cellular automaton animations in Neovim
- [Nixvim-Config](https://github.com/CodeBoyPhilo/Nixvim-Config/blob/87fac4c643889311d7b8e32bfa448e90c7c9308d/config/plugins/ui/dashboard/default.nix) - Dashboard configuration with asciiquarium integration that inspired the custom commands feature
