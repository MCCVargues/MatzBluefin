# Wire up fzf's key bindings (Ctrl-R history, Ctrl-T files, Alt-C cd) using
# fzf's own built-in fish integration. Only for interactive shells, and only
# if fzf is actually installed, so this stays a no-op elsewhere.
if status is-interactive && type -q fzf
    fzf --fish | source
end
