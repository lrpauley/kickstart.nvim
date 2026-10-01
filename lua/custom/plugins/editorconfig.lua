-- editorconfig (built into Neovim)
-- See `:help editorconfig`
--
-- Only apply `end_of_line` and `insert_final_newline` to new or empty files.
-- Existing files keep the line endings and final newline found on disk, so a
-- `.editorconfig` that doesn't match the repo (e.g. `end_of_line = crlf` in a
-- repo of LF files) can't rewrite whole files on save or make git tools like
-- gitsigns treat every line as changed / "Not Committed Yet".

local editorconfig = require 'editorconfig'

local function is_existing_file(bufnr)
  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr))
  return stat ~= nil and stat.size > 0
end

local set_end_of_line = editorconfig.properties.end_of_line
editorconfig.properties.end_of_line = function(bufnr, val, opts)
  if is_existing_file(bufnr) then return end
  set_end_of_line(bufnr, val, opts)
end

local set_insert_final_newline = editorconfig.properties.insert_final_newline
editorconfig.properties.insert_final_newline = function(bufnr, val, opts)
  if is_existing_file(bufnr) then
    -- Write back exactly what was read instead of adding or removing a final newline.
    vim.bo[bufnr].fixendofline = false
    return
  end
  set_insert_final_newline(bufnr, val, opts)
end
