local utils = require("screensaver.utils")
local M = {}

vim.api.nvim_set_hl(0, "Matrix", { fg = "#009900" })
vim.api.nvim_set_hl(0, "MatrixEnd", { fg = "#00FF00" })
vim.api.nvim_set_hl(0, "MatrixRnd", { fg = "#333333" })

vim.api.nvim_set_hl(0, "ScreensaverPipe1", { fg = "#FF0000" })
vim.api.nvim_set_hl(0, "ScreensaverPipe2", { fg = "#00FF00" })
vim.api.nvim_set_hl(0, "ScreensaverPipe3", { fg = "#0000FF" })
vim.api.nvim_set_hl(0, "ScreensaverPipe4", { fg = "#FFFF00" })
vim.api.nvim_set_hl(0, "ScreensaverPipe5", { fg = "#00FFFF" })
vim.api.nvim_set_hl(0, "ScreensaverPipe6", { fg = "#FF00FF" })

vim.api.nvim_set_hl(0, "ScreensaverFire1", { fg = "#550000" })
vim.api.nvim_set_hl(0, "ScreensaverFire2", { fg = "#AA0000" })
vim.api.nvim_set_hl(0, "ScreensaverFire3", { fg = "#FF0000" })
vim.api.nvim_set_hl(0, "ScreensaverFire4", { fg = "#FF5500" })
vim.api.nvim_set_hl(0, "ScreensaverFire5", { fg = "#FFAA00" })
vim.api.nvim_set_hl(0, "ScreensaverFire6", { fg = "#FFFF00" })
vim.api.nvim_set_hl(0, "ScreensaverFire7", { fg = "#FFFFFF" })

local animations = {}

local function blank_grid(width, height)
	local grid = {}
	for i = 1, height do
		local row = {}
		for j = 1, width do
			table.insert(row, { char = " ", hl_group = "" })
		end
		table.insert(grid, row)
	end
	return grid
end

local function put_char(grid, x, y, char, hl)
	if not grid[y] or not grid[y][x] then
		return
	end
	local width = vim.fn.strdisplaywidth(char)

	grid[y][x] = { char = char, hl_group = hl }

	if width > 1 then
		for i = 1, width - 1 do
			if grid[y][x + i] then
				grid[y][x + i] = { char = "", hl_group = "" } -- Mark as consumed
			end
		end
	end
end
