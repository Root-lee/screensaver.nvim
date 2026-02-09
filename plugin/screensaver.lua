local ok, ss = pcall(require, "screensaver")
if not ok then
  return
end

if not ss._loaded then
  ss._loaded = true
  ss.setup()
end

vim.api.nvim_create_user_command("ScreensaverStart", function()
  ss.start()
end, {})

vim.api.nvim_create_user_command("ScreensaverStop", function()
  ss.stop()
end, {})

vim.api.nvim_create_user_command("ScreensaverToggle", function()
  ss.toggle()
end, {})

vim.api.nvim_create_user_command("ScreensaverDisable", function()
  ss.disable()
end, {})
