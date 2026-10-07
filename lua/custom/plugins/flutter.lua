-- flutter-tools.nvim
-- https://github.com/nvim-flutter/flutter-tools.nvim
--
-- Flutter and Dart support: starts the Dart analysis server (`dartls`) and adds
-- commands to run the app, hot reload/restart, pick devices and emulators,
-- view the widget outline and open DevTools.
-- See `:help flutter-tools` for all available options.
--
-- The SDK is taken from the project's `.fvm/flutter_sdk` symlink when there is
-- one (created by `fvm install` / `fvm use` in the project), so each project
-- uses the Flutter version pinned in its `.fvmrc`. Otherwise `flutter` on PATH
-- is used. FVM detection looks upward from Neovim's cwd, so start Neovim inside
-- the project.
--
-- Style settings follow the Knownwell Flutter repos:
--  - Format on save with `dart format`, as `scripts/validate_codebase.sh` does.
--    The line length comes from `formatter: page_width` in the project's
--    `analysis_options.yaml` (90 in knownwell-patient-flutter-client), so no
--    line length is set here. Generated files are skipped, like in CI.
--  - A color column at that same page width.
--  - Lints are reported by `dartls` straight from `analysis_options.yaml`,
--    including the repo's own `kw_lints` analyzer plugin.
-- To save without formatting, use `:noautocmd write`.

vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim',
  { src = 'https://github.com/nvim-flutter/flutter-tools.nvim', version = vim.version.range '3.*' },
}

require('flutter-tools').setup {
  fvm = true,
  widget_guides = { enabled = true },
  lsp = { capabilities = require('blink.cmp').get_lsp_capabilities() },
}

-- Run configurations, picked from a list on :FlutterRun.
-- Keyed by the `name:` in pubspec.yaml of the project Neovim was started in.
local run_configs = {
  -- Flavors from android/app/flavors.gradle.kts (iOS schemes have the same names).
  knownwell_patient_app = {
    { name = 'Development', flavor = 'development' },
    { name = 'QA', flavor = 'qa' },
    { name = 'UAT', flavor = 'uat' },
    { name = 'Production', flavor = 'production' },
  },
}

local project_root = vim.fs.root(vim.uv.cwd(), 'pubspec.yaml')
if project_root then
  local pubspec = io.open(vim.fs.joinpath(project_root, 'pubspec.yaml'))
  if pubspec then
    local package = ('\n' .. pubspec:read '*a'):match '\nname:%s*([%w_]+)'
    pubspec:close()
    if run_configs[package] then require('flutter-tools').setup_project(run_configs[package]) end
  end
end

--- `formatter: page_width` from the nearest analysis_options.yaml, or the Dart default of 80.
---@param bufnr integer
---@return integer
local function page_width(bufnr)
  local root = vim.fs.root(bufnr, 'analysis_options.yaml')
  if root then
    local in_formatter = false
    for line in io.lines(vim.fs.joinpath(root, 'analysis_options.yaml')) do
      if line:match '^%S' then in_formatter = line:match '^formatter:' ~= nil end
      local width = in_formatter and line:match '^%s+page_width:%s*(%d+)'
      if width then
        return tonumber(width) --[[@as integer]]
      end
    end
  end
  return 80
end

--- Generated code, excluded from formatting and analysis in analysis_options.yaml.
---@param bufnr integer
---@return boolean
local function is_generated(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name:match '%.g%.dart$' ~= nil or name:match '/lib/generated/' ~= nil
end

local group = vim.api.nvim_create_augroup('custom-flutter', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'dart',
  callback = function(event)
    -- Effective Dart: two-space indentation, never tabs.
    vim.bo[event.buf].expandtab = true
    vim.bo[event.buf].shiftwidth = 2
    vim.bo[event.buf].tabstop = 2
    vim.bo[event.buf].softtabstop = 2
    vim.opt_local.colorcolumn = tostring(page_width(event.buf))
  end,
})

-- Format with the `dart format` CLI, the same command CI runs, rather than through dartls:
-- dartls can't answer format requests while it analyzes the project after startup.
-- Uses the project's FVM SDK when there is one, since `dart` may not be on PATH.
local conform = require 'conform'
conform.formatters.dart_format = {
  command = function(_, ctx)
    local fvm_root = vim.fs.root(ctx.dirname, '.fvm')
    local fvm_dart = fvm_root and vim.fs.joinpath(fvm_root, '.fvm', 'flutter_sdk', 'bin', 'dart')
    return fvm_dart and vim.fn.executable(fvm_dart) == 1 and fvm_dart or 'dart'
  end,
}
conform.formatters_by_ft.dart = { 'dart_format' }

vim.api.nvim_create_autocmd('BufWritePre', {
  group = group,
  pattern = '*.dart',
  callback = function(event)
    if is_generated(event.buf) then return end
    conform.format { bufnr = event.buf, timeout_ms = 5000 }
  end,
})

local function source_action(kind)
  return function() vim.lsp.buf.code_action { context = { only = { kind } }, apply = true } end
end

local map = function(keys, cmd, desc) vim.keymap.set('n', keys, cmd, { desc = 'Flutter: ' .. desc }) end
map('<leader>Fr', '<cmd>FlutterRun<CR>', '[R]un')
map('<leader>Fq', '<cmd>FlutterQuit<CR>', '[Q]uit')
map('<leader>Fh', '<cmd>FlutterReload<CR>', '[H]ot reload')
map('<leader>FR', '<cmd>FlutterRestart<CR>', 'Hot [R]estart')
map('<leader>Fd', '<cmd>FlutterDevices<CR>', '[D]evices')
map('<leader>Fe', '<cmd>FlutterEmulators<CR>', '[E]mulators')
map('<leader>Fl', '<cmd>FlutterLogToggle<CR>', 'Toggle [L]og')
map('<leader>Fo', '<cmd>FlutterOutlineToggle<CR>', 'Toggle widget [O]utline')
map('<leader>Ft', '<cmd>FlutterDevTools<CR>', 'Dev[T]ools')
map('<leader>Fc', '<cmd>FlutterCommands<CR>', 'All [C]ommands')
map('<leader>Fi', source_action 'source.organizeImports', 'Organize [I]mports')
map('<leader>Fx', source_action 'source.fixAll', 'Fi[x] all lints (like `dart fix`)')
require('which-key').add { { '<leader>F', group = '[F]lutter' } }
