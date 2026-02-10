local utils = require("screensaver.utils")
local M = {}

vim.api.nvim_set_hl(0, "Matrix", { fg = "#009900" })
vim.api.nvim_set_hl(0, "MatrixEnd", { fg = "#00FF00" })
vim.api.nvim_set_hl(0, "MatrixRnd", { fg = "#333333" })

local animations = {}

local function blank_lines(width, height)
  local line = string.rep(" ", width)
  local lines = {}
  for _ = 1, height do
    lines[#lines + 1] = line
  end
  return lines
end

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

animations.bounce = {
  fps = 12, 
  init = function(grid)
    local width = #grid[1]
    local height = #grid
    return {
      x = math.floor(width / 2),
      y = math.floor(height / 2),
      dx = 1,
      dy = 1,
      ch = "o",
      width = width,
      height = height
    }
  end,
  update = function(grid, state)
    for r = 1, state.height do
      for c = 1, state.width do
        grid[r][c] = { char = " ", hl_group = "" }
      end
    end
    
    local x = math.max(1, math.min(state.width, state.x))
    local y = math.max(1, math.min(state.height, state.y))
    
    grid[y][x] = { char = state.ch, hl_group = "Screensaver" }

    state.x = state.x + state.dx
    state.y = state.y + state.dy
    if state.x <= 1 or state.x >= state.width then
      state.dx = -state.dx
    end
    if state.y <= 1 or state.y >= state.height then
      state.dy = -state.dy
    end
    
    return true
  end,
}

animations.sine = {
  fps = 12,
  init = function(grid)
    local width = #grid[1]
    local height = #grid
    return { phase = 0, width = width, height = height }
  end,
  update = function(grid, state)
    for r = 1, state.height do
      for c = 1, state.width do
        grid[r][c] = { char = " ", hl_group = "" }
      end
    end
    
    local mid = math.floor(state.height / 2)
    for x = 1, state.width do
      local y = math.floor(mid + math.sin((x / state.width) * math.pi * 2 + state.phase) * (state.height / 3))
      y = math.max(1, math.min(state.height, y))
      grid[y][x] = { char = "*", hl_group = "Screensaver" }
    end
    state.phase = state.phase + 0.3
    return true
  end
}

local MatrixLine = {
  letters = "",
  position = 1,
  get_cell = function(self, l)
    if l < self.position and self.offset < l then
      if l == self.position - 1 then
        local random_char = math.random(1, utils.string_len(self.letters) or 1)
        return {
          char = utils.string_sub(self.letters, random_char, random_char),
          hl_group = "MatrixEnd",
        }
      else
        return {
          char = utils.string_sub(self.letters, l - self.offset, l - self.offset),
          hl_group = "Matrix",
        }
      end
    else
      return {
        char = string.char(math.random(33, 126)),
        hl_group = "MatrixRnd",
      }
    end
  end,
  update = function(self, height)
    self.position = self.position + 1
    if self.position > height or self.position > utils.string_len(self.letters) + self.offset then
      self.position = 1
      self.offset = math.random(math.floor(height / 4) + 1) - 1
    end
  end,
}

local function create_matrix_line(line_data)
  local characters = ""
  for i = 1, #line_data do
    characters = characters .. line_data[i].char
  end
  characters = string.gsub(characters, "^%s+", "")
  characters = string.gsub(characters, "%s+$", "")
  characters = string.gsub(characters, utils.nbsp, "")
  return characters
end

animations.matrix = {
  fps = 15,
  init = function(grid)
    local width = #grid[1]
    local height = #grid
    local valid_lines = {}
    
    for l = 1, height do
      local line = create_matrix_line(grid[l])
      if #line > height / 2 then
        table.insert(valid_lines, line)
      end
    end

    if #valid_lines == 0 then
      table.insert(valid_lines, "You are not working hard enough !!!")
      table.insert(valid_lines, "Don't you have anything better to do ???")
      table.insert(valid_lines, "Are you falling asleep ???")
      table.insert(valid_lines, "Wake up and do something !!!")
    end

    local lines = {}
    for l = 1, width do
      lines[l] = {
        letters = valid_lines[math.random(#valid_lines)],
        position = math.random(height),
        offset = math.random(math.floor(height / 4) + 1) - 1,
        get_cell = MatrixLine.get_cell,
        update = MatrixLine.update,
      }
    end
    return { lines = lines, width = width, height = height }
  end,
  update = function(grid, state)
    for r = 1, state.height do
      for c = 1, state.width do
        grid[r][c] = state.lines[c]:get_cell(r)
      end
    end
    for c = 1, state.width do
      state.lines[c]:update(state.height)
    end
    return true
  end
}

local shift_left = function(line)
  local chars = {}
  for i = 2, #line do
    table.insert(chars, line[i])
  end
  table.insert(chars, line[1])
  return chars
end

animations.move_left = {
  fps = 30,
  init = function(grid) return {} end,
  update = function(grid, state)
    utils.update_each(utils.is_not_empty, grid, shift_left)
    return true
  end
}

local shift_right = function(line)
  local chars = {}
  table.insert(chars, line[#line])
  for i = 1, #line - 1 do
    table.insert(chars, line[i])
  end
  return chars
end

animations.move_right = {
  fps = 30,
  init = function(grid) return {} end,
  update = function(grid, state)
    utils.update_each(utils.is_not_empty, grid, shift_right)
    return true
  end
}

local scramble = function(word)
  local chars = {}
  while #word ~= 0 do
    local index = math.random(1, #word)
    table.insert(chars, word[index])
    table.remove(word, index)
  end
  return chars
end

animations.scramble = {
  fps = 30,
  init = function(grid) return {} end,
  update = function(grid, state)
    utils.update_each(utils.is_not_whitespace, grid, scramble)
    return true
  end
}

local change_char_case = function(char)
  local new_char = char
  if char.char >= "A" and char.char <= "Z" then
    new_char.char = string.lower(char.char)
  else
    new_char.char = string.upper(char.char)
  end
  return new_char
end

local change_word_case = function(word)
  local chars = {}
  local random = math.random(0, #word)
  for i = 1, #word do
    if i == random then
      table.insert(chars, word[i])
    else
      table.insert(chars, change_char_case(word[i]))
    end
  end
  return chars
end

animations.random_case = {
  fps = 10,
  init = function(grid) return {} end,
  update = function(grid, state)
    utils.update_each(utils.is_letter, grid, change_word_case)
    return true
  end
}

animations.rain = {
  fps = 50,
  init = function(grid) 
    return { frame = 1, width = #grid[1], height = #grid, side_noise = true, disperse_rate = 3 } 
  end,
  update = function(grid, state)
    state.frame = state.frame + 1
    local width = state.width
    local height = state.height
    
    local function cell_empty(g, x, y)
      if x > 0 and x <= height and y > 0 and y <= width and (g[x][y].char == " " or g[x][y].char == utils.nbsp) then
        return true
      end
      return false
    end

    local function swap_cells(g, x1, y1, x2, y2)
      g[x1][y1], g[x2][y2] = g[x2][y2], g[x1][y1]
    end

    for i = 1, height do
      for j = 1, width do
        if grid[i][j] then grid[i][j].processed = false end
      end
    end

    local was_updated = false
    for x0 = height - 1, 1, -1 do
      for i = 1, width do
        local y0
        if (state.frame + x0) % 2 == 0 then
          y0 = i
        else
          y0 = width + 1 - i
        end
        
        local cell = grid[x0][y0]
        if not cell then goto continue end

        if cell.char == " " or cell.processed then
          goto continue
        end

        cell.processed = true

        if state.side_noise then
          local random = math.random()
          local side_step = 0.05
          if random < side_step then
            if cell_empty(grid, x0, y0 + 1) then
              swap_cells(grid, x0, y0, x0, y0 + 1)
              was_updated = true
            end
          elseif random < 2 * side_step then
            if cell_empty(grid, x0, y0 - 1) then
              swap_cells(grid, x0, y0, x0, y0 - 1)
              was_updated = true
            end
          end
        end

        if cell_empty(grid, x0 + 1, y0) then
          swap_cells(grid, x0, y0, x0 + 1, y0)
          was_updated = true
        else
          local disperse = cell.disperse_direction or ({ -1, 1 })[math.random(1, 2)]
          local last_pos = { x0, y0 }
          for d = 1, state.disperse_rate do
            local y = y0 + disperse * d
            if not cell_empty(grid, x0, y) then
              cell.disperse_direction = disperse * -1
              break
            elseif last_pos[1] == x0 then
              swap_cells(grid, last_pos[1], last_pos[2], x0, y)
              was_updated = true
              last_pos = { x0, y }
            end
            if cell_empty(grid, x0 + 1, y) then
              swap_cells(grid, last_pos[1], last_pos[2], x0 + 1, y)
              was_updated = true
              last_pos = { x0 + 1, y }
            end
          end
        end
        ::continue::
      end
    end
    return was_updated
  end
}

local function is_alive(grid, x, y)
  local row = grid[x]
  if not row then return false end
  local cell = row[y]
  if not cell then return false end
  return cell.char ~= " " and cell.char ~= utils.nbsp
end

local function get_neighbours(grid, x, y)
  local neighbours = {}
  local coords = {{-1,0},{-1,-1},{0,-1},{1,-1},{1,0},{1,1},{0,1},{-1,1}}
  for _, n in ipairs(coords) do
    if is_alive(grid, x + n[1], y + n[2]) then
      table.insert(neighbours, grid[x+n[1]][y+n[2]])
    end
  end
  return neighbours
end

animations.game_of_life = {
  fps = 10,
  init = function(grid) return { over = 4, under = 1, respawn = 3 } end,
  update = function(grid, state)
    local ref = vim.deepcopy(grid)
    local height = #grid
    local width = #grid[1]
    
    for i = 1, height do
      for j = 1, width do
        local n = #(get_neighbours(ref, i, j))
        if is_alive(ref, i, j) then
          if n >= state.over or n <= state.under then
            grid[i][j] = { char = utils.nbsp, hl_group = "" }
          end
        else
          if n == state.respawn then
            local neighs = get_neighbours(ref, i, j)
            if #neighs > 0 then
                grid[i][j] = vim.deepcopy(neighs[math.random(1, #neighs)])
            end
          end
        end
      end
    end
    return true
  end
}

M.get_animation = function(name)
  return animations[name]
end

M.get_all_names = function()
  local keys = {}
  for k in pairs(animations) do
    table.insert(keys, k)
  end
  return keys
end

return M
