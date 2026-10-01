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

# --- FL Studio ----------------------------------------------------------------
# The image ships wine, winetricks, wineasio and the nested labwc compositor;
# these recipes build the per-user Wine prefix and install FL into it.

# Build the FL Studio Wine prefix and run an installer in it
[group('fl-studio')]
fl-studio-install installer="":
    #!/usr/bin/bash
    set -euo pipefail

    installer="{{ installer }}"
    export WINEPREFIX="$(fl-studio --print-prefix)"

    # FL Studio is proprietary, so nothing is downloaded on your behalf, and
    # "latest" is the wrong thing to fetch anyway:
    #
    #   26.1.0.5530  last build known to run under plain Wine
    #   26.1.4.5589  first build known to refuse to start, with "The validity
    #                of the program could not be verified" -- its own
    #                Authenticode check failing. Wine 11.0 and 11.8 both fail
    #                identically, so it is not a Wine version to chase.
    #
    # Others report 26.1.3.5570 working; 26.1.1 and 26.1.2 are untested.
    # Image-Line serves old builds at
    # https://install.image-line.com/flstudio/flstudio_win64_<version>.exe
    # with no login, so a URL is usually the easiest way to pass one in.
    if [[ -z $installer ]]; then
        echo "Usage: ujust fl-studio-install <installer.exe|url>"
        echo
        echo "Do not use Image-Line's \"latest\" download: 26.1.4.5589 and"
        echo "later refuse to start under Wine. Older builds are still served"
        echo "by direct URL, no login needed, so this is all it takes:"
        echo
        echo "  ujust fl-studio-install \\"
        echo "    https://install.image-line.com/flstudio/flstudio_win64_26.1.0.5530.exe"
        echo
        echo "See the FL Studio section of the image README for which builds work."
        shopt -s nullglob
        candidates=("$HOME/Downloads"/[Ff][Ll]*[Ss]tudio*.exe)
        if (( ${#candidates[@]} )); then
            echo
            echo "Found in ~/Downloads:"
            printf '  %s\n' "${candidates[@]}"
        fi
        exit 1
    fi

    workdir=""
    cleanup() { [[ -z $workdir ]] || rm -rf "$workdir"; }
    trap cleanup EXIT

    if [[ $installer == http://* || $installer == https://* ]]; then
        workdir="$(mktemp -d)"
        echo ":: downloading $installer"
        curl -fL --progress-bar -o "$workdir/installer.exe" "$installer"
        installer="$workdir/installer.exe"
    fi
    [[ -f $installer ]] || { echo "no such file: $installer" >&2; exit 1; }

    # win64 is already the default for a WoW64 wine; stated so a stray
    # WINEARCH in the environment cannot produce a 32-bit prefix.
    export WINEARCH=win64
    # winemenubuilder disabled so wine does not scatter .desktop files through
    # ~/.local for everything it runs. wineboot then logs
    # "Error running cmd ... winemenubuilder.exe -a -r (126)"; that is this
    # line working, not a failure.
    export WINEDLLOVERRIDES='winemenubuilder.exe=d'

    echo ":: creating the Wine prefix at $WINEPREFIX"
    mkdir -p "$WINEPREFIX"
    wineboot -u

    # Graphics=x11 because Wine's Wayland driver cannot yet do what FL's UI
    # needs. Audio=alsa is not a preference: on Wine's PulseAudio backend FL's
    # main thread blocks forever in mmdevapi enumerating devices, so it sits on
    # the splash screen and never creates its main window. PipeWire serves ALSA
    # clients regardless. /usr/bin/fl-studio re-checks both on every launch.
    echo ":: setting the Wine graphics and audio drivers"
    wine reg add 'HKCU\Software\Wine\Drivers' /v Graphics /d x11 /f
    wine reg add 'HKCU\Software\Wine\Drivers' /v Audio /d alsa /f

    # tahoma separately from corefonts because FL's UI asks for that font by
    # name and corefonts does not carry it. (Wine also ships a Tahoma
    # replacement in /usr/share/wine/fonts, from wine-tahoma-winefonts.)
    #
    # One verb at a time, and a failure is collected rather than fatal. The
    # font and vcrun verbs need working 32-bit PE support -- winetricks
    # registers fonts with the syswow64 regedit -- which on this image depends
    # on the SELinux rule build.sh adds, and that only applies once you have
    # rebooted into an image built with it. FL Studio itself is 64-bit and runs
    # without any of these, so the install continues either way.
    #
    # wineboot copies wine's own bundled fonts into the prefix read-only (they
    # come from wine-tahoma-winefonts and friends) and winetricks' font verbs
    # rm them without -f, so rm stops and asks. Make them writable first,
    # otherwise an install blocks on a prompt halfway through.
    #
    # No -f on the verbs: winetricks then skips whatever it already recorded in
    # the prefix's winetricks.log, so re-running this recipe after a cancelled
    # installer is quick instead of redoing every download. Force a single verb
    # by hand if you need to redo one.
    echo ":: installing runtime bits with winetricks (this downloads a lot)"
    chmod -R u+w "$WINEPREFIX/drive_c/windows/Fonts" 2>/dev/null || true
    failed=()
    for verb in corefonts tahoma gdiplus vcrun2022 vcrun6sp6 dxvk; do
        echo ":: winetricks $verb"
        winetricks -q "$verb" || failed+=("$verb")
    done
    winetricks -q fontsmooth=rgb renderer=vulkan || failed+=("display-settings")

    echo ":: registering WineASIO (optional, ignore a failure here)"
    wine regsvr32 wineasio.dll || echo "   WineASIO not registered; see ujust fl-studio-asio"

    echo ":: running the FL Studio installer"
    fl-studio wine "$installer"

    if [[ -n "$(find "$WINEPREFIX/drive_c/Program Files/Image-Line" -maxdepth 3 -name FL64.exe -print -quit 2>/dev/null)" ]]; then
        echo
        echo "Done. Launch it with 'fl-studio' or from the app launcher."
    else
        echo
        echo "The installer finished but no FL64.exe turned up under"
        echo "$WINEPREFIX/drive_c/Program Files/Image-Line."
        echo "If you installed somewhere else, point FL_STUDIO_EXE at FL64.exe."
    fi

    if (( ${#failed[@]} )); then
        echo
        echo "These winetricks verbs did not complete: ${failed[*]}"
        echo "FL Studio still runs without them. To check whether 32-bit"
        echo "support is the reason:"
        echo
        echo "  WINEPREFIX=$WINEPREFIX \\"
        echo "    wine /usr/lib64/wine-wow64/wine/i386-windows/cmd.exe /c ver"
        echo
        echo "An execmod or \"noexec filesystem\" error there means you are on"
        echo "an image built before the SELinux rule in build.sh. Rebuild,"
        echo "reboot, then re-run just the verbs above with:"
        echo "  WINEPREFIX=$WINEPREFIX winetricks -q -f <verb>"
    fi

# Register WineASIO in the FL Studio prefix (ASIO -> JACK -> PipeWire)
[group('fl-studio')]
fl-studio-asio:
    #!/usr/bin/bash
    set -euo pipefail
    export WINEPREFIX="$(fl-studio --print-prefix)"
    [[ -d $WINEPREFIX ]] || { echo "no prefix yet; run: ujust fl-studio-install" >&2; exit 1; }
    # The image installs both halves of the driver into wine's own builtin
    # directories as wineasio.dll / wineasio.dll.so, so this needs no paths.
    wine regsvr32 wineasio.dll
    echo
    echo "Registered. In FL Studio: Options > Audio settings > Device > WineASIO."
    echo "Buffer size and channel counts live in HKCU\\Software\\Wine\\WineASIO;"
    echo "edit them with: WINEPREFIX=$WINEPREFIX wine regedit"

# Copy the nested labwc config into ~/.config for editing
[group('fl-studio')]
fl-studio-config:
    #!/usr/bin/bash
    set -euo pipefail
    src="/usr/share/fl-studio/labwc/rc.xml"
    dest="${XDG_CONFIG_HOME:-$HOME/.config}/fl-studio/labwc/rc.xml"
    if [[ -e $dest ]]; then
        echo "skip  $dest (already exists)"
    else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        echo "copy  $dest"
    fi
    echo
    echo "The launcher prefers this file over the image's copy. Delete it to go"
    echo "back to the default. labwc reloads it on SIGHUP, or restart FL."

# Delete the FL Studio Wine prefix, FL Studio and all its settings with it
[group('fl-studio')]
fl-studio-reset:
    #!/usr/bin/bash
    set -euo pipefail
    prefix="$(fl-studio --print-prefix)"
    [[ -d $prefix ]] || { echo "nothing to remove at $prefix"; exit 0; }
    echo "This deletes $prefix, including FL Studio and anything stored inside"
    echo "the prefix. Projects under ~/Documents are not touched."
    read -rp "Type 'yes' to continue: " reply
    [[ $reply == yes ]] || { echo "aborted"; exit 1; }
    rm -rf "$prefix"
    echo "removed $prefix"
