-- Options
vim.opt.number = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Files & Backups
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Mappings
vim.keymap.set('n', '0', '^') -- move to first non-blank character
vim.keymap.set('x', 'p', 'pgvy') -- prepare for the second pasting
vim.keymap.set('n', 'j', 'gj') -- treat long lines as break lines (useful when moving around in them)
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('i', '(', '()<Left>') -- auto-pairing parentheses
vim.keymap.set('i', '[', '[]<Left>')
vim.keymap.set('i', '{', '{}<Left>')

-- Last position jump (from our previous discussion)
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
