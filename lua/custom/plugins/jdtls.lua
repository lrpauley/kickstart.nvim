-- nvim-jdtls
-- https://github.com/mfussenegger/nvim-jdtls
--
-- Java support via Eclipse JDT Language Server, with extras beyond plain LSP
-- (organize imports, extract variable/method, test running, etc.).
-- See `:help jdtls` for all available functions and options.
--
-- The `jdtls` server is installed by Mason. It requires a Java 21+ runtime,
-- found through `JAVA_HOME` or `java` on your PATH.
--
-- nvim-jdtls starts the server itself, so `jdtls` must NOT be added to the
-- `servers` table in init.lua (that would start a second, conflicting client).

vim.pack.add { 'https://github.com/mfussenegger/nvim-jdtls' }

-- Install the server through Mason (mason.nvim is set up in init.lua before custom plugins load).
local registry = require 'mason-registry'
registry.refresh(function()
  local ok, pkg = pcall(registry.get_package, 'jdtls')
  if ok and not pkg:is_installed() then pkg:install() end
end)

local java_ok ---@type boolean?
local function has_java()
  if java_ok == nil then
    -- `java -version` rather than `executable('java')`: macOS ships a /usr/bin/java stub without a JDK.
    java_ok = vim.system({ 'java', '-version' }):wait().code == 0
  end
  return java_ok
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-jdtls', { clear = true }),
  pattern = 'java',
  callback = function(event)
    if vim.fn.executable 'jdtls' ~= 1 then
      vim.notify_once('jdtls is not installed yet. Check :Mason', vim.log.levels.WARN)
      return
    end
    if not has_java() then
      vim.notify_once('jdtls needs a Java 21+ runtime (JAVA_HOME or `java` on PATH)', vim.log.levels.WARN)
      return
    end

    local root_markers = { 'mvnw', 'gradlew', 'settings.gradle', 'settings.gradle.kts', 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git' }
    local root_dir = vim.fs.root(event.buf, root_markers) or vim.fs.dirname(vim.api.nvim_buf_get_name(event.buf))

    -- jdtls keeps per-project index data here; each project needs its own directory.
    local workspace_dir = vim.fs.joinpath(vim.fn.stdpath 'cache', 'jdtls', 'workspace', (root_dir:gsub('[/\\:]', '%%')))

    require('jdtls').start_or_attach {
      cmd = { 'jdtls', '-data', workspace_dir },
      root_dir = root_dir,
      capabilities = require('blink.cmp').get_lsp_capabilities(),
    }
  end,
})
