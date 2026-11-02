# dotfiles

Personal dotfiles for **Linux** (Arch/CachyOS), **macOS**, and **Windows**
(Git Bash + [scoop](https://scoop.sh)), managed with
[chezmoi](https://www.chezmoi.io).

## What's managed

| File | Purpose |
|---|---|
| `.bashrc` / `.bash_profile` / `.profile` | bash: aliases, history, navigation; guarded tool envs (uv, rustup) |
| `.zshrc` / `.zshenv` | zsh equivalents |
| `.inputrc` | arrow keys search history by prefix |
| `.config/nvim/init.lua` | Neovim 0.12+: vim.pack plugins, snacks.nvim, lualine, gitsigns, nvim-lint, LSP (rust-analyzer), Nord theme |
| `.gitconfig` / `.gitconfig-mktmind` | git identity; per-remote org switching via `includeIf` |
| `.config/gh-autoswitch.sh` | `gh` wrapper that auto-switches account to match the repo remote |
| `.ssh/config` | GitHub identities only — personal/infra hosts go in `config.local` (see below) |
| `.tmux.conf` | plain tmux syntax (also read by [psmux](https://github.com/psmux/psmux) on Windows) |
| `.vimrc` | rust.vim formatting settings |

## Machine-local overrides (never committed)

- `~/.bashrc.local`, `~/.zshrc.local` — sourced if present; personal tooling lives here
- `~/.ssh/config.local` — deploy boxes, jump hosts, employer infra. The managed
  `~/.ssh/config` must keep its `Include config.local` **above** all `Host`
  blocks (an `Include` after a `Host` block is scoped inside it).

## Bootstrap

Linux / macOS:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply dairycow
```

Windows (PowerShell; repo needs auth via gh):

```powershell
scoop install git chezmoi gh
gh auth login
setx XDG_CONFIG_HOME "%USERPROFILE%\.config"   # so nvim finds ~\.config\nvim
chezmoi init --apply https://github.com/dairycow/dotfiles.git
```

## Notes

- Neovim requires 0.12+ (uses the built-in `vim.pack` manager); treesitter
  parsers need a C compiler (`gcc` / `clang` / mingw).
- Tooling assumed by the shell configs: `eza`, `tmux` (or `psmux` on Windows),
  `gh`. Everything degrades gracefully if a tool is missing.
