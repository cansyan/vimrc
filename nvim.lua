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
--vim.keymap.set('i', '(', '()<Left>') -- auto-pairing parentheses
--vim.keymap.set('i', '[', '[]<Left>')
--vim.keymap.set('i', '{', '{}<Left>')

-- leader key mapping
vim.g.mapleader = " "
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Write' })
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
vim.keymap.set('n', '<leader>x', ':x<CR>', { desc = 'Write and quit' })

-- default diagnostic keymap is [d and ]d
--vim.keymap.set("n", "<leader>d", function()
--  local diagnostics = vim.diagnostic.get(0) -- Get diagnostics for current buffer
--  if #diagnostics > 0 then
--    vim.diagnostic.setloclist()
--  else
--    vim.notify("No diagnostics found for this buffer", vim.log.levels.INFO)
--  end
--end, { desc = "Show Diagnostic Location List" })

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

-- LSP
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function(ev)
    vim.lsp.start({
      name = "gopls",
      cmd = { "gopls" },
      root_dir = vim.fs.root(ev.buf, { "go.work", "go.mod", ".git" }),
    })
  end,
})

-- default keymap
-- grn: vim.lsp.buf.rename() (Rename symbol)
-- grr: vim.lsp.buf.references() (List references)
-- gra: vim.lsp.buf.code_action() (Select code action)
-- gri: vim.lsp.buf.implementation() (Go to implementation)
-- grt: vim.lsp.buf.type_definition() (Go to type definition)
-- gO: vim.lsp.buf.document_symbol() (List document symbols)
-- K: Displays hover information

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    -- Essential keymaps for definition, implementation, hover, rename, and actions
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover, opts)
  end,
})

-- Format and organize imports on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
	vim.lsp.buf.code_action({
      context = { only = { "source.organizeImports" } },
      apply = true,
    })

    vim.lsp.buf.format({ async = false })
  end,
})

-- Keep the sign column fixed on screen so it never toggles dynamically.
-- This completely prevents text shifting when errors appear or disappear
vim.opt.signcolumn = "yes"
-- disable preview on completion
vim.opt.completeopt = { "menu", "menuone", "noselect" }
