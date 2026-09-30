#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux

### Shell: fish, with fzf integration
# fish's own postinstall scriptlet registers it in /etc/shells, so
# `chsh -s /usr/bin/fish` works right away for any user.
#
# fzf's key bindings (Ctrl-R history search, Ctrl-T file search, Alt-C cd)
# are wired up for fish via system_files/etc/fish/conf.d/fzf.fish, which
# runs `fzf --fish | source` -- fzf's own built-in fish integration, rather
# than sourcing /usr/share/fzf/shell/key-bindings.fish by hand.
dnf5 install -y fish fzf

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

### Tiling window manager: niri
# niri is a scrollable-tiling Wayland compositor. It ships its own
# /usr/share/wayland-sessions/niri.desktop, so GDM lists "Niri" automatically
# and GNOME remains the default session -- nothing about the GNOME desktop
# changes. Everything below is in the Fedora repos, so no COPR is needed.
#
# Session configuration lives in system_files/:
#   /etc/niri/config.kdl        compositor, keybinds, startup
#   /etc/xdg/waybar/            status bar
#   /etc/xdg/mako/config        notifications
#   /etc/xdg/fuzzel/fuzzel.ini  app launcher
#
# Run `ujust niri-config` on the host to copy these into ~/.config for editing.
dnf5 install -y \
    niri \
    xwayland-satellite \
    waybar \
    fuzzel \
    mako \
    swaybg \
    swayidle \
    swaylock \
    mate-polkit \
    brightnessctl \
    playerctl \
    wl-clipboard \
    wlr-randr

# The waybar and fuzzel packages each own a config file under /etc/xdg, which
# the install above just wrote over the copies taken from system_files/ at the
# top of this script. Re-apply system_files/ so this image's configuration wins
# regardless of which packages are installed later.
cp -avf "/ctx/system_files"/. /

# Notes on the supporting pieces, since the reasoning is not obvious from the
# package list alone:
# - xwayland-satellite: niri >= 25.08 starts it on demand and exports $DISPLAY
#   itself, so X11 apps work with no configuration.
# - mako: D-Bus activated (fr.emersion.mako.service), so it must not be spawned
#   from the niri config or it would run twice.
# - mate-polkit: provides a polkit agent for GUI password prompts. GNOME's agent
#   lives inside gnome-shell and is therefore unavailable in a niri session.
#   Its own autostart file is OnlyShowIn=MATE, so niri's config starts it
#   explicitly; this also keeps it from loading under GNOME.
# - swaylock ships /etc/pam.d/swaylock, so unlocking authenticates correctly.
# - gnome-control-center refuses to start outside GNOME/Unity, and its
#   .desktop ships OnlyShowIn=GNOME so it's hidden from the launcher under
#   niri. system_files/usr/share/applications/org.gnome.Settings.desktop
#   overrides it to launch via
#   `env XDG_CURRENT_DESKTOP=niri:GNOME gnome-control-center` (the GNOME
#   token keeps xdg-desktop-portal on the niri backend) and drops
#   OnlyShowIn/DBusActivatable so it shows up and starts under niri too.

#### Example for enabling a System Unit File

systemctl enable podman.socket
