local M = {}

M.ignored_buftypes = {
  'nofile',
  'quickfix',
  'prompt',
}
M.ignored_filetypes = {
  'NvimTree',
}

local win_pos = {
  start = 0,
  middle = 1,
  last = 2,
}

function M.win_position(direction, for_resizing)
  local directions
  if direction == 'left' or direction == 'right' then
    directions = { 'h', 'l' }
  else
    directions = { 'k', 'j' }
  end

  local cur_win = vim.api.nvim_get_current_win()
  local cur_win_ignored = vim.tbl_contains(M.ignored_buftypes, vim.bo.buftype)
    or vim.tbl_contains(M.ignored_filetypes, vim.bo.filetype)
  vim.cmd('wincmd ' .. directions[1])
  if
    for_resizing
    and not cur_win_ignored
    and (vim.tbl_contains(M.ignored_buftypes, vim.bo.buftype) or vim.tbl_contains(M.ignored_filetypes, vim.bo.filetype))
  then
    vim.cmd('wincmd ' .. directions[2])
  end
  local new_win = vim.api.nvim_get_current_win()
  vim.cmd('wincmd ' .. directions[1])
  if
    for_resizing
    and not cur_win_ignored
    and (vim.tbl_contains(M.ignored_buftypes, vim.bo.buftype) or vim.tbl_contains(M.ignored_filetypes, vim.bo.filetype))
  then
    vim.cmd('wincmd ' .. directions[2])
  end
  local new_win2 = vim.api.nvim_get_current_win()
  for _ = 0, 3, 1 do
    vim.cmd('wincmd ' .. directions[2])
  end
  if
    for_resizing
    and not cur_win_ignored
    and (vim.tbl_contains(M.ignored_buftypes, vim.bo.buftype) or vim.tbl_contains(M.ignored_filetypes, vim.bo.filetype))
  then
    vim.cmd('wincmd ' .. directions[1])
  end
  local new_win3 = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(cur_win)

  if new_win == cur_win then
    return win_pos.start
  end

  -- at left or op edge, or in one of the middle of > 2 splits
  if cur_win ~= new_win and cur_win ~= new_win3 and new_win2 ~= new_win3 then
    return win_pos.middle
  end

  return win_pos.last
end

local function compute_direction_vertical(direction)
  local current_pos = M.win_position(direction, true)
  if current_pos == win_pos.start or current_pos == win_pos.middle then
    return direction == 'down' and '+' or '-'
  end

  return direction == 'down' and '-' or '+'
end

local function compute_direction_horizontal(direction)
  local current_pos = M.win_position(direction, true)
  print(current_pos)
  print(direction)
  if current_pos == win_pos.start or current_pos == win_pos.middle then
    return direction == 'right' and '+' or '-'
  end

  return direction == 'right' and '-' or '+'
end

local function resize(direction, amount)
  amount = amount or 3
  -- for vertical height account for tabline, status line, and cmd line
  local window_height = vim.o.lines - 1 - vim.o.cmdheight
  if (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1) or vim.o.showtabline == 2 then
    window_height = window_height - 1
  end

  local is_full_height = vim.api.nvim_win_get_height(0) == window_height
  local is_full_width = vim.api.nvim_win_get_width(0) == vim.o.columns

  -- don't try to horizontally resize a full width window
  if (direction == 'left' or direction == 'right') and is_full_width then
    return
  end

  -- don't try to vertically resize a full height window
  if (direction == 'down' or direction == 'up') and is_full_height then
    return
  end

  -- vertically
  if direction == 'down' or direction == 'up' then
    local plus_minus = compute_direction_vertical(direction)
    vim.cmd(string.format('resize %s%s', plus_minus, amount))
    return
  end

  -- horizontally
  local plus_minus = compute_direction_horizontal(direction)
  vim.cmd(string.format('vertical resize %s%s', plus_minus, amount))
end

local function move_cursor(direction)
  local current_pos = M.win_position(direction)
  if current_pos == win_pos.start and (direction == 'left' or direction == 'up') then
    local wincmd = 'wincmd ' .. (direction == 'left' and 'l' or 'j')
    for _ = 0, #vim.api.nvim_tabpage_list_wins(0), 1 do
      vim.cmd(wincmd)
    end
    return
  end

  if current_pos == win_pos.last and (direction == 'right' or direction == 'down') then
    local wincmd = 'wincmd ' .. (direction == 'right' and 'h' or 'k')
    for _ = 0, #vim.api.nvim_tabpage_list_wins(0), 1 do
      vim.cmd(wincmd)
    end
    return
  end

  local wincmd_direction
  if direction == 'left' or direction == 'right' then
    wincmd_direction = direction == 'left' and 'h' or 'l'
  else
    wincmd_direction = direction == 'up' and 'k' or 'j'
  end

  vim.cmd('wincmd ' .. wincmd_direction)
end

vim.tbl_map(function(direction)
  M[string.format('resize_%s', direction)] = function(amount)
    resize(direction, amount)
  end
  M[string.format('move_cursor_%s', direction)] = function()
    move_cursor(direction)
  end
end, {
  'left',
  'right',
  'up',
  'down',
})

return M
