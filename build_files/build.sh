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

### Clipboard manager: cliphist
# cliphist keeps a history of everything copied via wl-clipboard and hands it
# back through a dmenu-style picker -- here, fuzzel. It isn't in Fedora's
# repos, only COPR, so the COPR is enabled just for this install and disabled
# again immediately after so it doesn't stay enabled on the final image.
#
# The watcher daemon is started from niri's config (spawn-at-startup
# "wl-paste" "--watch" "cliphist" "store"); Mod+Shift+C opens the picker.
dnf5 -y copr enable alternateved/cliphist
dnf5 install -y cliphist
dnf5 -y copr disable alternateved/cliphist

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

### FL Studio under Wine
# FL Studio itself is proprietary and is installed per-user into a Wine prefix
# by `ujust fl-studio-install`; this only puts the pieces it needs on the image.
# /usr/bin/fl-studio then starts FL inside a nested labwc compositor, and
# /usr/share/fl-studio/labwc/rc.xml configures that compositor. See the README
# for why the nesting is necessary under niri.
#
# Fedora 44's wine is a WoW64 build (/usr/lib64/wine-wow64/, 64-bit unix
# libraries plus both PE architectures), which is what FL wants. Two
# non-obvious things about the package list:
#
# - The `wine` meta-package requires wine-pulseaudio but *not* wine-alsa, and
#   FL has to be pointed at ALSA: with Wine's PulseAudio backend FL's main
#   thread blocks forever inside mmdevapi enumerating devices and the main
#   window is never created. winealsa.drv comes from wine-alsa, hence the
#   explicit entry. (PipeWire serves ALSA clients, so nothing is given up.)
# - labwc execs Xwayland rather than linking it, so it has no RPM dependency
#   on it. niri's xwayland-satellite happens to pull it in, but FL's setup
#   should not depend on the niri session being installed, so it is listed.
dnf5 install -y \
    wine \
    wine-alsa \
    winetricks \
    labwc \
    xorg-x11-server-Xwayland

### WineASIO: the optional low-latency audio path for FL Studio
# ASIO -> JACK -> PipeWire, as an alternative to FL's default (DirectSound via
# winealsa). Not in Fedora's repos, so it comes from the audinux COPR, enabled
# only for this install like the cliphist one above.
#
# It drags in jack-audio-connection-kit for a dependency it does not really
# use: the driver dlopens libjack.so.0 by soname, and ldconfig resolves that to
# PipeWire's implementation in /usr/lib64/pipewire-0.3/jack/, which comes first
# in the search path via /etc/ld.so.conf.d/pipewire-jack-x86_64.conf. jackd
# itself is never started. python3-qt5 comes along for `wineasio-settings`.
dnf5 -y copr enable ycollet/audinux
dnf5 install -y wineasio
dnf5 -y copr disable ycollet/audinux

# As shipped the driver cannot be loaded at all, for two separate reasons:
#
# 1. The package installs into /usr/lib64/wine/, while Fedora's wine looks in
#    /usr/lib64/wine-wow64/.
# 2. Wine derives a builtin's unix library name from the name inside the PE
#    stub, which is wineasio.dll (it is built from wineasio.dll.spec), but the
#    pair is shipped as wineasio64.dll / wineasio64.dll.so. Wine looks for
#    wineasio.dll.so, finds nothing, and fails with "cannot find builtin
#    library".
#
# Installing both halves into wine's own builtin directories under the name
# wine expects means `wine regsvr32 wineasio.dll` works in any prefix, with no
# WINEDLLPATH and no copying DLLs into each prefix's system32. Registering it
# in a prefix is still per-user: `ujust fl-studio-asio`.
install -D -m0755 /usr/lib64/wine/x86_64-windows/wineasio64.dll \
    /usr/lib64/wine-wow64/wine/x86_64-windows/wineasio.dll
install -D -m0755 /usr/lib64/wine/x86_64-unix/wineasio64.dll.so \
    /usr/lib64/wine-wow64/wine/x86_64-unix/wineasio.dll.so

#### Example for enabling a System Unit File

systemctl enable podman.socket
