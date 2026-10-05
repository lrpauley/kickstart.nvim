-- Java format on save, changed lines only
--
-- Mirrors the IntelliJ "Actions on Save > Reformat code (Changed lines)" setup the
-- Knownwell Java repos ask for: on save, only the lines that differ from the last
-- commit are formatted, so untouched code never gets reformatted into noisy diffs.
-- Files that are not committed yet are formatted in full.
--
-- Formatting itself is done by jdtls, using the Eclipse formatter profile in
-- `java-format.xml` (wired up in jdtls.lua), tuned to match the IntelliJ code
-- style in those repos' `.editorconfig`.
--
-- `<leader>f` still formats the whole buffer (or the visual selection).
-- To save without formatting, use `:noautocmd write`.

--- Line ranges ({ first, last }, 1-based) of `bufnr` that differ from HEAD.
--- Returns nil if the buffer is not in a git repo.
---@param bufnr integer
---@return [integer, integer][]?
local function changed_ranges(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local git = { cwd = vim.fs.dirname(path), text = true }

  if vim.system({ 'git', 'rev-parse', '--is-inside-work-tree' }, git):wait().code ~= 0 then return nil end

  local head = vim.system({ 'git', 'show', 'HEAD:./' .. vim.fs.basename(path) }, git):wait()
  if head.code ~= 0 then return { { 1, line_count } } end

  -- Compare without carriage returns: the buffer holds lines without them even for CRLF files.
  local before = head.stdout:gsub('\r\n', '\n')
  local after = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n') .. '\n'

  local ranges = {}
  for _, hunk in ipairs(vim.text.diff(before, after, { result_type = 'indices', algorithm = 'histogram' })) do
    local start, count = hunk[3], hunk[4]
    if count > 0 then table.insert(ranges, { start, start + count - 1 }) end
  end
  return ranges
end

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('custom-java-format', { clear = true }),
  pattern = '*.java',
  callback = function(event)
    if #vim.lsp.get_clients { bufnr = event.buf, name = 'jdtls' } == 0 then return end

    local ranges = changed_ranges(event.buf)
    if not ranges then return end

    -- Bottom-up, so formatting one range can't shift the line numbers of the ones above it.
    for i = #ranges, 1, -1 do
      local first, last = ranges[i][1], ranges[i][2]
      local last_col = #vim.api.nvim_buf_get_lines(event.buf, last - 1, last, false)[1]
      vim.lsp.buf.format {
        bufnr = event.buf,
        name = 'jdtls',
        async = false,
        timeout_ms = 2000,
        range = { start = { first, 0 }, ['end'] = { last, last_col } },
      }
    end
  end,
})
