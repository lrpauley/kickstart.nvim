-- mermaid.nvim
-- https://github.com/kevalin/mermaid.nvim
--
-- Mermaid diagram support for `.mmd` / `.mermaid` files: live browser preview,
-- formatting, linting and inline terminal rendering.
-- See `:help mermaid` for all available options.
--
-- Syntax highlighting comes from the Tree-sitter `mermaid` parser, which the
-- Tree-sitter setup in init.lua installs automatically the first time a
-- mermaid file is opened.
--
-- Optional external tools:
--  - `mmdc` (npm install -g @mermaid-js/mermaid-cli) for diagnostics and :MermaidRender
--  - Kitty/Ghostty, or `chafa`, for :MermaidRender inline rendering
-- Without them, :MermaidPreview (browser) and :MermaidFormat still work.

vim.pack.add { 'https://github.com/kevalin/mermaid.nvim' }
require('mermaid').setup {}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-mermaid', { clear = true }),
  pattern = 'mermaid',
  callback = function(event)
    local map = function(keys, cmd, desc) vim.keymap.set('n', keys, cmd, { buffer = event.buf, desc = 'Mermaid: ' .. desc }) end
    map('<leader>mp', '<cmd>MermaidPreview<CR>', '[P]review in browser')
    map('<leader>mx', '<cmd>MermaidPreviewStop<CR>', 'Stop preview')
    map('<leader>mf', '<cmd>MermaidFormat<CR>', '[F]ormat buffer')
    map('<leader>mr', '<cmd>MermaidRender<CR>', '[R]ender inline')
    map('<leader>mc', '<cmd>MermaidCopyURL<CR>', '[C]opy preview URL')
    require('which-key').add { { '<leader>m', group = '[M]ermaid', buffer = event.buf } }
  end,
})
