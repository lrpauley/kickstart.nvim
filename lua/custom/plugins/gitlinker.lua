-- gitlinker.nvim
-- https://github.com/linrongbin16/gitlinker.nvim
--
-- Builds a permalink to the current line (or visual selection) on the git
-- host, e.g. GitHub. Links point at the current commit, so the commit must be
-- pushed for the link to work for others.
-- See `:help gitlinker` for all available options.

vim.pack.add { { src = 'https://github.com/linrongbin16/gitlinker.nvim', version = vim.version.range '5.*' } }
require('gitlinker').setup {}

-- gitlinker's own "lines can be wrong due to file change" warning never fires
-- when Neovim's cwd differs from the file's directory (it passes a cwd-relative
-- path to `git diff` but runs it from the file's directory), and its message is
-- the full URL, which triggers a hit-enter prompt in narrow windows.
-- So we silence it and report a short message with our own change check,
-- trimmed to `v:echospace` so it never triggers the prompt.
local function permalink(action, verb)
  return function()
    local file = vim.api.nvim_buf_get_name(0)
    require('gitlinker').link {
      message = false,
      action = function(url)
        action(url)
        local rev = url:match('/(' .. string.rep('%x', 40) .. ')/') or 'HEAD'
        local lines = url:match '#(L%d+.*)$' or 'file'
        local diff = vim.system({ 'git', 'diff', '--quiet', rev, '--', file }, { cwd = vim.fs.dirname(file) }):wait()
        local msg, level = ('%s %s link'):format(verb, lines), vim.log.levels.INFO
        if vim.bo.modified or diff.code == 1 then
          msg, level = ('%s, file changed since %s'):format(msg, rev:sub(1, 7)), vim.log.levels.WARN
        end
        vim.notify(msg:sub(1, vim.v.echospace), level)
      end,
    }
  end
end

local actions = require 'gitlinker.actions'
vim.keymap.set({ 'n', 'v' }, '<leader>gy', permalink(actions.clipboard, 'Copied'), { desc = '[G]it: [Y]ank permalink' })
vim.keymap.set({ 'n', 'v' }, '<leader>gY', permalink(actions.system, 'Opened'), { desc = '[G]it: open permalink in browser' })
require('which-key').add { { '<leader>g', group = '[G]it', mode = { 'n', 'v' } } }
