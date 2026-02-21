# VHS Tape - screensaver.nvim Demo
# https://github.com/charmbracelet/vhs

# Output settings
Output demo.gif
Set TypingSpeed 50ms
Set PlaybackSpeed 0.7

# Terminal settings - 1080p
Set FontFamily "Monaco"
Set FontSize 22
Set Width 1920
Set Height 1080
Set Padding 20
Set Margin 20
Set MarginFill "#1e1e2e"
Set BorderRadius 12

# Window chrome
Set WindowBar Colorful
Set WindowBarSize 40

# Theme - Catppuccin Mocha style
Set Theme "Catppuccin Mocha"

# ============================================================
# Demo Script
# ============================================================

# Prepare: copy demo_content.txt to /tmp
Hide
Type "cp ./demo.lua /tmp/demo.lua"
Enter
Show

# Open demo file
Type "nvim /tmp/demo.lua"
Enter
Sleep 1s

# ============================================================
# Demo 1: matrix
# ============================================================

Type ":lua require('screensaver').start('matrix')"
Enter
Sleep 5s

# ============================================================
# Demo 2: rain
# ============================================================

Escape
Sleep 500ms
Type ":lua require('screensaver').start('rain')"
Enter
Sleep 5s

# ============================================================
# Demo 3: starfield
# ============================================================

Escape
Sleep 500ms
Type ":lua require('screensaver').start('starfield')"
Enter
Sleep 5s

# ============================================================
# Demo 4: aquarium (custom command)
# ============================================================

Escape
Sleep 500ms
Type ":lua require('screensaver').start('aquarium')"
Enter
Sleep 8s

# ============================================================
# Demo 5: sl (steam locomotive)
# ============================================================

Escape
Sleep 500ms
Type ":lua require('screensaver').start('sl')"
Enter
Sleep 10s

# ============================================================
# End demo
# ============================================================

Escape
Sleep 500ms
Type ":q"
Enter
Sleep 500ms
