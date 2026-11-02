# Auto-switch the active `gh` CLI account to match the current git repo's
# origin remote — mirrors the SSH host aliases in ~/.ssh/config so a `gh`
# command (pr/release/etc.) acts as the profile that owns the repo:
#   github-mktmind:…  or  github.com:mktmind/   -> mktmind-hf
#   everything else (incl. outside any repo)                    -> dairycow
# Switches only when the active account differs (parsed from
# ~/.config/gh/hosts.yml), so the common path stays fast.
# Bypass for one command:  GH_NO_AUTOSWITCH=1 gh …
gh() {
  if [ -z "$GH_NO_AUTOSWITCH" ]; then
    local want=dairycow url=
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      url=$(git config remote.origin.url 2>/dev/null || true)
      case "$url" in
        *github-mktmind*|*github.com:mktmind/*|*github.com/mktmind/*)
          want=mktmind-hf ;;
      esac
    fi
    local active=
    active=$(sed -n 's/^    user: //p' "$HOME/.config/gh/hosts.yml" 2>/dev/null)
    if [ -n "$active" ] && [ "$active" != "$want" ]; then
      command gh auth switch -u "$want" >/dev/null 2>&1
    fi
  fi
  command gh "$@"
}
