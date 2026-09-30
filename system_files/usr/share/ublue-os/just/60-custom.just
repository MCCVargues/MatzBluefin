# Custom recipes for this image. Imported by /usr/share/ublue-os/just/00-entry.just.

# Copy the system niri/waybar/mako/fuzzel configs into ~/.config for editing
[group('niri')]
niri-config:
    #!/usr/bin/bash
    set -euo pipefail
    declare -A sources=(
        ["niri/config.kdl"]="/etc/niri/config.kdl"
        ["waybar/config.jsonc"]="/etc/xdg/waybar/config.jsonc"
        ["waybar/style.css"]="/etc/xdg/waybar/style.css"
        ["mako/config"]="/etc/xdg/mako/config"
        ["fuzzel/fuzzel.ini"]="/etc/xdg/fuzzel/fuzzel.ini"
    )
    config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    for rel in "${!sources[@]}"; do
        src="${sources[$rel]}"
        dest="$config_home/$rel"
        if [[ ! -f "$src" ]]; then
            echo "skip  $rel (missing $src)"
            continue
        fi
        if [[ -e "$dest" ]]; then
            echo "skip  $dest (already exists)"
            continue
        fi
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        echo "copy  $dest"
    done
    echo
    echo "User configs take precedence over the system ones. Delete a file to"
    echo "fall back to the image default. niri reloads config.kdl on save."

# Check a niri config for errors (defaults to the one niri would actually load)
[group('niri')]
niri-validate config="":
    #!/usr/bin/bash
    set -euo pipefail
    target="{{ config }}"
    if [[ -z "$target" ]]; then
        config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
        if [[ -f "$config_home/niri/config.kdl" ]]; then
            target="$config_home/niri/config.kdl"
        else
            target="/etc/niri/config.kdl"
        fi
    fi
    echo "Validating $target"
    niri validate -c "$target"

# Show the niri session log for this boot
[group('niri')]
niri-log:
    journalctl --user-unit=niri -b --no-pager
