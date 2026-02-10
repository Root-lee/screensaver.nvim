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

animations.starfield = {
  fps = 20,
  init = function(grid)
    local width = #grid[1]
    local height = #grid
    local stars = {}
    local num_stars = math.floor(width * height / 30)
    for _ = 1, num_stars do
      table.insert(stars, {
        x = math.random(-width, width),
        y = math.random(-height, height),
        z = math.random(1, width),
      })
    end
    return { stars = stars, width = width, height = height, cx = math.floor(width/2), cy = math.floor(height/2) }
  end,
  update = function(grid, state)
    for r = 1, state.height do
      for c = 1, state.width do
        grid[r][c] = { char = " ", hl_group = "" }
      end
    end

    for _, star in ipairs(state.stars) do
      star.z = star.z - 1
      if star.z <= 0 then
        star.x = math.random(-state.width, state.width)
        star.y = math.random(-state.height, state.height)
        star.z = state.width
      end

      local sx = math.floor((star.x / star.z) * state.width/2 + state.cx)
      local sy = math.floor((star.y / star.z) * state.height/2 + state.cy)

      if sx >= 1 and sx <= state.width and sy >= 1 and sy <= state.height then
        local char = "."
        if star.z < state.width / 4 then char = "@"
        elseif star.z < state.width / 2 then char = "*"
        elseif star.z < state.width / 1.5 then char = "+"
        end
        grid[sy][sx] = { char = char, hl_group = "Screensaver" }
      end
    end
    return true
  end
}

animations.pipes = {
  fps = 10,
  init = function(grid)
    local width = #grid[1]
    local height = #grid
    local pipes = {}
    for i = 1, 3 do
      table.insert(pipes, {
        x = math.random(1, width),
        y = math.random(1, height),
        dx = 0,
        dy = 0,
        hl = "ScreensaverPipe" .. math.random(1, 6)
      })
    end
    return { pipes = pipes, width = width, height = height, clear_tick = 0 }
  end,
  update = function(grid, state)
    state.clear_tick = state.clear_tick + 1
    if state.clear_tick > 200 then
      for r = 1, state.height do
        for c = 1, state.width do
          grid[r][c] = { char = " ", hl_group = "" }
        end
      end
      state.clear_tick = 0
    end

    for _, pipe in ipairs(state.pipes) do
      local old_x, old_y = pipe.x, pipe.y
      local old_dx, old_dy = pipe.dx, pipe.dy

      if math.random() < 0.2 or (pipe.dx == 0 and pipe.dy == 0) then
        local dirs = {{0,1}, {0,-1}, {1,0}, {-1,0}}
        local d = dirs[math.random(1, 4)]
        if d[1] ~= -pipe.dx or d[2] ~= -pipe.dy then
          pipe.dx = d[1]
          pipe.dy = d[2]
        end
      end

      pipe.x = pipe.x + pipe.dx
      pipe.y = pipe.y + pipe.dy

      if pipe.x < 1 then pipe.x = state.width end
      if pipe.x > state.width then pipe.x = 1 end
      if pipe.y < 1 then pipe.y = state.height end
      if pipe.y > state.height then pipe.y = 1 end

      local char = "│"
      if pipe.dx ~= 0 then char = "─" end
      
      if old_dx ~= pipe.dx or old_dy ~= pipe.dy then
        if (old_dy == 1 and pipe.dx == 1) or (old_dx == -1 and pipe.dy == -1) then char = "┌"
        elseif (old_dy == 1 and pipe.dx == -1) or (old_dx == 1 and pipe.dy == -1) then char = "┐"
        elseif (old_dy == -1 and pipe.dx == 1) or (old_dx == -1 and pipe.dy == 1) then char = "└"
        elseif (old_dy == -1 and pipe.dx == -1) or (old_dx == 1 and pipe.dy == 1) then char = "┘"
        else char = "+" end
      end

      if old_dx == 0 and old_dy == 0 then
        if pipe.dx ~= 0 then char = "─" else char = "│" end
      end

      grid[pipe.y][pipe.x] = { char = char, hl_group = pipe.hl }
    end
    return true
  end
}

animations.fire = {
  fps = 15,
  init = function(grid)
    local width = #grid[1]
    local height = #grid
    local heat = {}
    for r = 1, height do
      heat[r] = {}
      for c = 1, width do
        heat[r][c] = 0
      end
    end
    return { heat = heat, width = width, height = height }
  end,
  update = function(grid, state)
    local chars = { " ", ".", ",", "-", "~", ":", ";", "=", "!", "*", "#", "$", "@" }
    local hls = { "", "ScreensaverFire1", "ScreensaverFire1", "ScreensaverFire2", "ScreensaverFire2", "ScreensaverFire3", "ScreensaverFire3", "ScreensaverFire4", "ScreensaverFire4", "ScreensaverFire5", "ScreensaverFire5", "ScreensaverFire6", "ScreensaverFire7" }
    
    for c = 1, state.width do
      state.heat[state.height][c] = math.random(0, #chars * 3) 
    end

    for r = 1, state.height - 1 do
      for c = 1, state.width do
        local sum = 0
        local count = 0
        if state.heat[r+1] then
          sum = sum + state.heat[r+1][c]
          count = count + 1
          if c > 1 then sum = sum + state.heat[r+1][c-1]; count = count + 1 end
          if c < state.width then sum = sum + state.heat[r+1][c+1]; count = count + 1 end
        end
        
        state.heat[r][c] = math.max(0, math.floor(sum / count) - math.random(0, 1))
        
        local val = state.heat[r][c]
        local idx = math.min(#chars, math.max(1, math.floor(val)))
        
        local hl = hls[idx]
        if idx == 1 then hl = "" end
        
        grid[r][c] = { char = chars[idx], hl_group = hl }
      end
    end
    
    for c = 1, state.width do
       grid[state.height][c] = { char = "@", hl_group = "ScreensaverFire7" }
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
