local M = {}

M.nbsp = " "

M.get_char = function(grid, i, j)
	local row = grid[i]
	if not row then
		return ""
	end
	local c = row[j]
	if c then
		return c.char
	else
		return ""
	end
end

M.is_upper = function(grid, i, j)
	local c = M.get_char(grid, i, j)
	return c >= "A" and c <= "Z"
end

M.is_lower = function(grid, i, j)
	local c = M.get_char(grid, i, j)
	return c >= "a" and c <= "z"
end

M.is_letter = function(grid, i, j)
	return M.is_upper(grid, i, j) or M.is_lower(grid, i, j)
end

M.is_number = function(grid, i, j)
	local c = M.get_char(grid, i, j)
	return c >= "0" and c <= "9"
end

M.is_alphanum = function(grid, i, j)
	return M.is_letter(grid, i, j) or M.is_number(grid, i, j)
end

M.is_whitespace = function(grid, i, j)
	local c = M.get_char(grid, i, j)
	return c == " " or c == "\t" or c == "\n" or c == "\r" or c == M.nbsp
end

M.is_not_whitespace = function(grid, i, j)
	return not M.is_whitespace(grid, i, j)
end

M.is_empty = function(grid, i, j)
	return M.get_char(grid, i, j) == M.nbsp
end

M.is_not_empty = function(grid, i, j)
	return not M.is_empty(grid, i, j)
end

M.update_each = function(conditional, grid, word_update)
	for i = 1, #grid do
		local processed = {}
		local word = {}
		for j = 1, #grid[i] do
			local c = grid[i][j]
			if conditional(grid, i, j) then
				table.insert(word, c)
			else
				if #word ~= 0 then
					for _, d in pairs(word_update(word)) do
						table.insert(processed, d)
					end
					word = {}
				end
				table.insert(processed, c)
			end
		end

		if #word ~= 0 then
			for _, d in pairs(word_update(word)) do
				table.insert(processed, d)
			end
		end

		grid[i] = processed
	end
	return true
end

M.string_len = function(str)
	return vim.fn.strdisplaywidth(str)
end

M.string_byte_len = function(str)
	return string.len(str)
end

M.string_sub = function(str, i, j)
	local length = vim.str_utfindex(str)
	if i < 0 then
		i = i + length + 1
	end
	if j and j < 0 then
		j = j + length + 1
	end
	local u = (i > 0) and i or 1
	local v = (j and j <= length) and j or length
	if u > v then
		return ""
	end
	local s = vim.str_byteindex(str, u - 1)
	local e = vim.str_byteindex(str, v)
	return str:sub(s + 1, e)
end

-- Helper to get highlight group at position
local function get_highlight_at(buf, row, col)
	if vim.treesitter.highlighter.active[buf] then
		local captures = vim.treesitter.get_captures_at_pos(buf, row, col)
		if captures and #captures > 0 then
			local capture = captures[#captures]
			if capture and capture.capture then
				return "@" .. capture.capture
			end
		end
	end

	local syn_id = vim.fn.synID(row + 1, col + 1, 1)
	if syn_id ~= 0 then
		syn_id = vim.fn.synIDtrans(syn_id)
		return vim.fn.synIDattr(syn_id, "name")
	end

	return ""
end

M.snapshot_window = function(win)
	local buf = vim.api.nvim_win_get_buf(win)

	-- Use nvim_buf_get_lines to get content.
	-- We capture the visible portion based on scroll position (topline).
	local info = vim.fn.getwininfo(win)[1]
	local topline = info.topline - 1
	local botline = info.botline

	local lines = vim.api.nvim_buf_get_lines(buf, topline, botline, false)
	local width = vim.api.nvim_win_get_width(win)
	local height = vim.api.nvim_win_get_height(win)

	local grid = {}

	for i = 1, height do
		local line_str = lines[i] or ""
		local row = {}
		local buf_row = topline + i - 1

		for j = 1, width do
			local char = M.string_sub(line_str, j, j)
			local hl = ""

			if char ~= "" and char ~= " " then
				local char_idx = j - 1 -- 0-based char index
				if char_idx < vim.str_utfindex(line_str) then
					local byte_col = vim.str_byteindex(line_str, char_idx)
					hl = get_highlight_at(buf, buf_row, byte_col)
				end
			end

			if char == "" then
				char = " "
			end
			table.insert(row, { char = char, hl_group = hl })
		end
		table.insert(grid, row)
	end
	return grid
end

return M
