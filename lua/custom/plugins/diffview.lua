-- diffview+ (diffview-plus.nvim)
-- https://github.com/dlyongemallo/diffview-plus.nvim
--
-- Side-by-side diffs of every changed file in one tab, with a file panel for
-- staging, plus file and repo history. This is the actively maintained fork of
-- sindrets/diffview.nvim, which has had no commits since mid 2024.
-- See `:help diffview` for all available options, or press `g?` in a diffview
-- for its keymaps.
--
-- In `<leader>gd` (working tree vs. index):
--  - `-` / `s` stages or unstages the file under the cursor, `S` / `U` stages
--    or unstages everything.
--  - The left side is the index, so `dp` in the right window puts a hunk into
--    it, and `:w` there stages it. gitsigns' `<leader>hs` also works on the right.

-- Pinned to a release tag, since its tags are two-part (`v0.38`) and so don't
-- match a `vim.version.range()`. Bump it by hand to update.
vim.pack.add { { src = 'https://github.com/dlyongemallo/diffview-plus.nvim', version = 'v0.38' } }
require('diffview').setup {
  -- Color deleted lines as deletions instead of as diff filler
  enhanced_diff_hl = true,
  -- File icons and the default folder signs are Nerd Font glyphs
  use_icons = vim.g.have_nerd_font,
  signs = vim.g.have_nerd_font and {} or { fold_closed = '▸', fold_open = '▾' },
}

vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewToggle<CR>', { desc = '[G]it: toggle [D]iff view of all changes' })
vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', { desc = '[G]it: current file [H]istory' })
vim.keymap.set('n', '<leader>gH', '<cmd>DiffviewFileHistory<CR>', { desc = '[G]it: repo [H]istory' })
