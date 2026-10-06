-- render-markdown.nvim
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
--
-- Renders Markdown inside the buffer: styled headings, code blocks, tables,
-- checkboxes, callouts and links. Off by default so Markdown files open as
-- plain text; toggle it per buffer with `<leader>tm`. The line under the
-- cursor always shows the raw text, and insert mode shows the whole buffer raw.
-- See `:help render-markdown` for all available options.
--
-- Uses the Tree-sitter `markdown` / `markdown_inline` parsers set up in
-- init.lua. Code block language icons come from mini.icons, so they only show
-- when `vim.g.have_nerd_font` is set.

vim.pack.add { { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim', version = vim.version.range '8.*' } }
local render_markdown = require 'render-markdown'

-- The default icons are Nerd Font glyphs, which show up as missing-glyph boxes
-- without a Nerd Font. Swap them for plain Unicode, or drop them where there is
-- no good equivalent (headings then keep their '#' markers).
-- Unlike the defaults, the checkbox icons have no trailing space, since a
-- plain Unicode glyph does not spill into the `right_pad` cell like a Nerd
-- Font glyph does.
local function plain_icons()
  local default = render_markdown.default
  local callout = {}
  for name, config in pairs(default.callout) do
    -- Callout titles are overlaid on the raw text, e.g. '[!NOTE]', so pad them
    -- to its width to cover it completely.
    local title = config.rendered:gsub('^%S+ ', '')
    callout[name] = { rendered = title .. (' '):rep(#config.raw - #title) }
  end
  local custom_links = {}
  for name in pairs(default.link.custom) do
    custom_links[name] = { icon = '' }
  end
  return {
    heading = { icons = {} },
    sign = { enabled = false },
    checkbox = {
      unchecked = { icon = '☐' },
      checked = { icon = '☑' },
      custom = { todo = { rendered = '◐' } },
    },
    callout = callout,
    link = { footnote = { icon = '' }, image = '', email = '', hyperlink = '', wiki = { icon = '' }, custom = custom_links },
  }
end

render_markdown.setup(vim.tbl_deep_extend('force', {
  enabled = false,
  -- LaTeX needs the `latex` Tree-sitter parser and an external converter (utftex or latex2text)
  latex = { enabled = false },
}, vim.g.have_nerd_font and {} or plain_icons()))

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-render-markdown', { clear = true }),
  pattern = 'markdown',
  callback = function(event) vim.keymap.set('n', '<leader>tm', render_markdown.buf_toggle, { buffer = event.buf, desc = '[T]oggle rendered [M]arkdown' }) end,
})
