-- Neovim config: Python + Rust setup with the Nord theme
-- Relative line numbers, Treesitter highlighting, vim.pack (built-in plugin
-- manager), snacks.picker / snacks.explorer, lualine (branch only), bufferline,
-- which-key, gitsigns, nvim-lint (ruff + mypy), nvim-lspconfig (rust-analyzer:
-- gd/gD/gr jumps + <leader>fs symbols).

-- Basic options
vim.o.number = true
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.g.mapleader = " "

-- Standard options pack
vim.o.undofile = true      -- undo history survives restarts
vim.o.ignorecase = true    -- case-insensitive search...
vim.o.smartcase = true     -- ...unless the pattern has capitals
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.signcolumn = "yes"   -- no jitter when signs (git/diagnostics) appear
vim.o.cursorline = true
vim.o.scrolloff = 8        -- keep context visible around the cursor

-- Build markdown-preview.nvim after install/update: downloads the prebuilt
-- frontend (no node/yarn needed). Must be registered before vim.pack.add()
-- to catch installs coming from the lockfile (see :h vim.pack-events).
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local d = ev.data
    if d.spec.name == "markdown-preview.nvim" and (d.kind == "install" or d.kind == "update") then
      if not d.active then vim.cmd.packadd("markdown-preview.nvim") end
      vim.fn["mkdp#util#install"]()
    end
  end,
})

-- Plugins via vim.pack, Neovim's built-in plugin manager (0.12+).
-- First run clones everything; afterwards the exact state is pinned in
-- nvim-pack-lock.json next to this file (commit it). Update with
-- vim.pack.update() — confirm the review buffer with :w, discard with :q.
vim.pack.add({
  "https://github.com/gbprod/nord.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/folke/snacks.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/akinsho/bufferline.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/mfussenegger/nvim-lint",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/iamcco/markdown-preview.nvim",
})

-- Colorscheme: Nord (gbprod port) — dim slate chrome with a cyan accent, the
-- established theme closest to the ask/askc TUI look
vim.cmd.colorscheme("nord")

-- Statusline (git branch only)
require("lualine").setup({
  options = { theme = "nord" },
  sections = {
    lualine_a = {},
    lualine_b = { "branch" },
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
})

-- Open buffers as a tabline
require("bufferline").setup({})
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bd", function() require("snacks").bufdelete() end, { desc = "Close buffer" })

-- Keymap hints when pausing after <leader>
require("which-key").setup({})
require("which-key").add({
  { "<leader>f", group = "find" },
  { "<leader>h", group = "git hunk" },
  { "<leader>m", group = "markdown" },
})

-- Git gutter signs, hunk navigation, line blame
require("gitsigns").setup({
  on_attach = function(bufnr)
    local opts = function(desc)
      return { buffer = bufnr, desc = desc }
    end
    vim.keymap.set("n", "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<cr>'", { buffer = bufnr, expr = true, desc = "Next hunk" })
    vim.keymap.set("n", "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<cr>'", { buffer = bufnr, expr = true, desc = "Prev hunk" })
    vim.keymap.set("n", "<leader>hb", "<cmd>Gitsigns blame_line<cr>", opts("Blame line"))
  end,
})

-- Fuzzy finder + file explorer
-- Guarded so re-sourcing this file (e.g. :source after an edit) doesn't
-- trigger "snacks.nvim is already setup".
local snacks = require("snacks")
if not snacks.did_setup then
  snacks.setup({
    picker = {},
    explorer = {},
  })
end
vim.keymap.set("n", "<leader>ff", function() snacks.picker.files() end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", function() snacks.picker.grep() end, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", function() snacks.picker.buffers() end, { desc = "Buffers" })
-- Symbols in the current file (classes, methods, ...): via LSP when a client
-- is attached, else via Treesitter (works in any file with a parser).
vim.keymap.set("n", "<leader>fs", function()
  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/documentSymbol" }) > 0 then
    snacks.picker.lsp_symbols()
  else
    snacks.picker.treesitter()
  end
end, { desc = "Find symbols in file" })
vim.keymap.set("n", "<leader>e", function()
  local explorer = snacks.picker.get({ source = "explorer" })[1]
  if explorer then explorer:close() else snacks.explorer.reveal() end
end, { desc = "Toggle file explorer" })

-- LSP: code navigation for Rust. Server configs come from nvim-lspconfig,
-- activated with the built-in vim.lsp API (Neovim 0.11+). rust-analyzer is
-- installed via rustup. Add more servers the same way, e.g.
-- vim.lsp.enable("basedpyright").
-- K (hover) is a Neovim default once an LSP is attached.
vim.lsp.enable("rust_analyzer")

-- Mapping `gr` for references shadows Neovim's grn/gra/grr defaults
-- (rename/action/references), so rename and code action get explicit maps.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = function(desc)
      return { buffer = ev.buf, desc = desc }
    end
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
    vim.keymap.set("n", "gr", function() snacks.picker.lsp_references() end, opts("References"))
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
  end,
})

-- Markdown preview: live-updating page in the browser, mermaid diagrams rendered.
-- Always opens in the dedicated "xdg-open" Firefox profile, matching the
-- ~/.local/bin/firefox-xdg-profile wrapper (same as the text/html handler).
vim.g.mkdp_browser = "firefox-xdg-profile"
-- Keep the preview page open after hiding/closing the markdown buffer.
vim.g.mkdp_auto_close = 0
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown preview" })

-- Python linting: ruff (style + lint) and mypy (types)
-- Install once with: uv tool install ruff mypy
require("lint").linters_by_ft = { python = { "ruff", "mypy" } }
vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
  callback = function()
    -- quietly skip linters whose binary isn't installed yet
    require("lint").try_lint(nil, {
      filter = function(linter)
        local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
        return cmd == nil or vim.fn.executable(cmd) == 1
      end,
    })
  end,
})

-- Treesitter: install parsers, then highlight any filetype that has one
require("nvim-treesitter").install {
  "python", "toml", "markdown", "markdown_inline", -- Python project files
  "rust", -- volsmith (Rust workspace)
  "json", "yaml", "bash", "diff",
  "lua", "vim", "vimdoc", "query", -- editing this config
}
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang then pcall(vim.treesitter.start, args.buf, lang) end
  end,
})

-- Reload buffers when files change on disk (external edits, git checkouts, etc.)
-- Requires `set -g focus-events on` in ~/.tmux.conf for FocusGained to fire inside tmux.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  pattern = "*",
  command = "checktime",
})
