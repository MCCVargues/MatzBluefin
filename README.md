# image-template

This repository is meant to be a template for building your own custom [bootc](https://github.com/bootc-dev/bootc) image. This template is the recommended way to make customizations to any image published by the Universal Blue Project.

# The niri tiling session

This image adds [niri](https://github.com/niri-wm/niri), a scrollable-tiling
Wayland compositor, as a **second session alongside GNOME**. GNOME stays the
default and is not modified in any way; pick "Niri" from the gear menu on the
GDM login screen to use it.

Everything comes from the Fedora repos, so there is no COPR to track.

## Configuration

The session is configured image-wide, not per user:

| File | Purpose |
| --- | --- |
| `/etc/niri/config.kdl` | Compositor: input, layout, startup, keybinds |
| `/etc/xdg/waybar/config.jsonc` | Status bar modules |
| `/etc/xdg/waybar/style.css` | Status bar theme |
| `/etc/xdg/mako/config` | Notification popups |
| `/etc/xdg/fuzzel/fuzzel.ini` | Application launcher |

niri reads `~/.config/niri/config.kdl` first and falls back to `/etc/niri/config.kdl`,
and the other three follow the same pattern. To start tweaking things, copy the
system files into your home directory:

```bash
ujust niri-config      # copy system configs into ~/.config (never overwrites)
ujust niri-validate    # check a niri config for errors
ujust niri-log         # show this boot's niri session log
```

Deleting a file from `~/.config` falls back to the image default. niri reloads
`config.kdl` as soon as you save it.

## Keybindings

`Mod` is the Super (Windows) key. Press <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>/</kbd>
at any time for the full in-session list.

niri tiles windows in **columns** on a horizontally scrolling strip, rather than
subdividing the screen. A column can hold several stacked windows.

### Apps and session

| Bind | Action |
| --- | --- |
| <kbd>Mod</kbd>+<kbd>Return</kbd> / <kbd>Mod</kbd>+<kbd>T</kbd> | Terminal (Ptyxis) |
| <kbd>Mod</kbd>+<kbd>D</kbd> / <kbd>Mod</kbd>+<kbd>Space</kbd> | App launcher (fuzzel) |
| <kbd>Mod</kbd>+<kbd>E</kbd> | Files (Nautilus) |
| <kbd>Mod</kbd>+<kbd>Q</kbd> | Close window |
| <kbd>Mod</kbd>+<kbd>O</kbd> | Overview (zoomed-out workspaces) |
| <kbd>Mod</kbd>+<kbd>N</kbd> / <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | Dismiss one / all notifications |
| <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>L</kbd> | Lock screen |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> | Exit niri (asks first) |
| <kbd>Print</kbd> | Screenshot (<kbd>Ctrl</kbd> screen, <kbd>Alt</kbd> window) |

### Moving around

| Bind | Action |
| --- | --- |
| <kbd>Mod</kbd>+<kbd>H</kbd>/<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd> or arrows | Focus left column / down / up / right column |
| <kbd>Mod</kbd>+<kbd>Ctrl</kbd>+ those | Move the window |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+ those | Focus another monitor |
| <kbd>Mod</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | Go to workspace |
| <kbd>Mod</kbd>+<kbd>Ctrl</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | Send column to workspace |
| <kbd>Mod</kbd>+<kbd>U</kbd> / <kbd>Mod</kbd>+<kbd>I</kbd> | Workspace down / up |
| <kbd>Mod</kbd>+<kbd>Tab</kbd> | Previous workspace |
| <kbd>Mod</kbd>+<kbd>Home</kbd> / <kbd>End</kbd> | First / last column |

### Sizing and arranging

| Bind | Action |
| --- | --- |
| <kbd>Mod</kbd>+<kbd>R</kbd> | Cycle column width (⅓ → ½ → ⅔) |
| <kbd>Mod</kbd>+<kbd>-</kbd> / <kbd>Mod</kbd>+<kbd>=</kbd> | Narrow / widen by 10% |
| <kbd>Mod</kbd>+<kbd>F</kbd> | Maximize column |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> | Fullscreen |
| <kbd>Mod</kbd>+<kbd>C</kbd> | Center column |
| <kbd>Mod</kbd>+<kbd>[</kbd> / <kbd>Mod</kbd>+<kbd>]</kbd> | Pull window into / push out of column |
| <kbd>Mod</kbd>+<kbd>W</kbd> | Toggle tabbed column |
| <kbd>Mod</kbd>+<kbd>V</kbd> | Toggle floating |

## What else is included

- **X11 apps** work through `xwayland-satellite`, which niri starts on demand and
  wires up to `$DISPLAY` itself — no configuration needed.
- **Notifications** via `mako` (D-Bus activated, so it starts on first use).
- **Password prompts** via `mate-polkit`; GNOME's agent lives inside
  `gnome-shell` and so is unavailable here.
- **Idle behaviour**: lock at 10 minutes, screens off at 15, lock before sleep
  (`swayidle` + `swaylock`).
- **Wallpaper**: `swaybg`, set to a stock Bluefin background. swaybg decodes via
  gdk-pixbuf, which on Fedora 44 routes to the sandboxed glycin loaders and
  covers `jxl`, `webp`, `avif`, `heic`, `png`, `jpeg`, `svg`, `tiff`, `bmp` and
  `ico` — so anything in `/usr/share/backgrounds/` works. Change the
  `spawn-at-startup "swaybg"` line in `config.kdl`.

### Things left at defaults on purpose

- `prefer-no-csd` is **off**. It looks better under tiling, but it changes how
  many of the GTK apps on this image draw their window decorations. Uncomment it
  in `config.kdl` if you want it.
- Monitors are auto-detected. To pin resolution, scale or position, run
  `niri msg outputs` inside a niri session to get the real connector names, then
  add an `output` block to `config.kdl`.
- The keyboard layout is deliberately **not** set in `config.kdl`, so niri takes
  it from `localectl` — the same layout GNOME uses.

The niri package installs its own docs at `/usr/share/doc/niri/wiki/`.

# FL Studio

FL Studio runs under Wine on this image. The packages, the launcher and the
nested compositor it needs are part of the image; the prefix is built per-user
by `ujust fl-studio-install`. FL Studio is proprietary and is not shipped here,
so you supply the installer.

One systemic difference from the setup this was ported from: Fedora's `wine`
11.0 is a Staging build — it reports itself as `wine-11.0 (Staging)` — where
that one ran plain Wine 11. Nothing below depends on the staging patches, but it
is the first thing to suspect if something behaves differently.

## Installing

```bash
ujust fl-studio-install ~/Downloads/flstudio_win_26.1.0.5530.exe
```

**Pin the version.** Following Image-Line's "latest" download gets you a build
that will not start:

| Build | Behaviour under Wine |
| --- | --- |
| `26.1.0.5530` | Last build known to work |
| `26.1.1` – `26.1.3` | Never tested, either way |
| `26.1.4.5589` | First build known to fail: *"The validity of the program could not be verified"* |

That failure is FL's own Authenticode check, not a Wine bug — Wine 11.0 and
11.8 fail identically, so there is no Wine version to chase. Image-Line's forum
names `26.1.0.5530` as the last build that runs, and older installers come from
the customer archive in their tech support, behind your account.

The recipe creates the prefix at `~/.local/share/fl-studio/prefix`, sets the two
registry values below, installs `corefonts tahoma gdiplus vcrun2022 vcrun6sp6
dxvk` plus `fontsmooth=rgb` and `renderer=vulkan` with winetricks, registers
WineASIO, and then runs your installer. Expect it to download a few hundred MB.
`tahoma` is listed separately from `corefonts` because FL's UI asks for that
font by name and corefonts does not carry it.

One note on DXVK: Fedora also ships it as `wine-dxvk*`, wired up through
`alternatives` for every prefix on the system, but it is not the selected
alternative by default. The recipe uses winetricks' `dxvk` verb instead, which
is prefix-local and is what the setup this was built from used.

## Running

`fl-studio`, or **FL Studio** in the app launcher. The launcher also takes a
command, to run other Wine tools against the same prefix:

```bash
fl-studio                              # FL Studio
fl-studio winecfg                      # winecfg, in the same nested session
fl-studio wine ~/Downloads/plugin.exe  # install a plugin
fl-studio --help                       # options and environment variables
```

## The two settings that decide whether it starts

Both live in `HKCU\Software\Wine\Drivers` in the prefix. `ujust
fl-studio-install` writes them, and `/usr/bin/fl-studio` re-checks them on every
launch by reading `user.reg`, because getting them wrong looks like a hang
rather than an error.

- **`Audio=alsa`** is not a preference. With Wine's PulseAudio backend FL's main
  thread blocks forever inside mmdevapi enumerating devices — the backtrace runs
  ntdll ← kernelbase ← mmdevapi ← winmm ×4 ← flengine_x64 — so it sits on the
  splash screen and the main window is never created. PipeWire serves ALSA
  clients anyway, so nothing is given up. `winealsa.drv` comes from the
  `wine-alsa` package, which the `wine` meta-package does *not* pull in: it
  requires `wine-pulseaudio` instead, so `build.sh` lists `wine-alsa`
  explicitly.
- **`Graphics=x11`** because Wine's Wayland driver cannot yet do what FL's UI
  needs.

## Why FL runs in a nested compositor

This is the niri-specific part, and it is not in any generic Wine guide.

FL positions and sizes its own X11 windows. Under bare Xwayland it repaints on
resize but never re-lays-out, so resizing its niri column leaves the window
black. niri's own Xwayland notes say as much: X11 apps that position their own
windows "will need a nested compositor to run".

So `fl-studio` starts a nested [labwc](https://labwc.github.io/) and runs FL
inside it. niri tiles labwc like any other window, labwc resizes its nested
output to match, and FL gets a genuine X11 resize, which it does handle. labwc
is started with `-S`, so closing FL ends the nested session.

A Wine virtual desktop (`wine explorer /desktop=`) also kills the black, but
only by being a fixed canvas: shrinking the column clips FL instead of
re-laying it out.

Two consequences worth knowing:

- The window niri sees is labwc's, with `app-id` `labwc`, so niri rules matching
  `fl64.exe` never fire. `config.kdl` has one rule for `^labwc$` that opens it
  maximized.
- Inside labwc, `Super`+`Shift`+`Q` ends the nested session. FL has no titlebar
  there, and labwc's own keybinds and its `Alt`-chorded mousebinds are switched
  off so that FL gets `Alt`+`Tab`, `Alt`+`F4`, `Alt`+`Space` and `Alt`-drag
  itself.

`/usr/share/fl-studio/labwc/rc.xml` configures that compositor, and explains why
its maximize rule has to match on window title: FL puts up 41 top-level X11
windows, all with `WM_CLASS` `fl64.exe` — the main window, its dialogs and about
30 1×1 helpers. A rule matching only the identifier stretches the welcome dialog
across the output, and that dialog is one that repaints without re-laying-out,
so it goes black and looks exactly like the original bug.

`ujust fl-studio-config` copies that file to `~/.config/fl-studio/labwc/rc.xml`,
which the launcher prefers if it exists.

## Audio

Out of the box FL uses its default driver through `winealsa.drv`, which
PipeWire serves. For low latency there is **WineASIO** (ASIO → JACK →
PipeWire), already registered by `ujust fl-studio-install`; pick it under
*Options → Audio settings → Device*. `ujust fl-studio-asio` re-registers it,
which is worth doing after a Wine update.

WineASIO needs two fixes to be loadable at all on Fedora, both applied in
`build.sh`: the audinux package installs into `/usr/lib64/wine/` while Fedora's
wine looks in `/usr/lib64/wine-wow64/`, and Wine derives a builtin's unix
library name from the name inside the PE stub — `wineasio.dll`, from
`wineasio.dll.spec` — while the pair ships as `wineasio64.dll` /
`wineasio64.dll.so`. Wine looks for `wineasio.dll.so`, finds nothing, and fails
with *"cannot find builtin library"*. The image installs both halves into wine's
own builtin directories under the name wine expects, so `wine regsvr32
wineasio.dll` works in any prefix with no `WINEDLLPATH` and no per-prefix DLL
copying.

Buffer size and channel counts live in `HKCU\Software\Wine\WineASIO`; edit
them with `WINEPREFIX=$(fl-studio --print-prefix) wine regedit`.

## Still not fixed

- FL occasionally draws white until you hover it or click something: it repaints
  on input but not on its own.
- labwc logs `No free output buffer slot` under wlroots.

Neither is solved, and neither appears to be fatal.

## Files and recipes

| File | Purpose |
| --- | --- |
| `/usr/bin/fl-studio` | Launcher: prefix, Wine environment, nested labwc |
| `/usr/share/fl-studio/labwc/rc.xml` | The nested compositor's configuration |
| `/usr/share/applications/fl-studio.desktop` | App launcher entry |
| `~/.local/share/fl-studio/prefix` | The Wine prefix (override with `FL_STUDIO_PREFIX`) |

```bash
ujust fl-studio-install <installer.exe|url>   # build the prefix and install FL
ujust fl-studio-asio                          # (re-)register WineASIO
ujust fl-studio-config                        # copy the labwc config to ~/.config
ujust fl-studio-reset                         # delete the prefix, FL and all
```

# Community

If you have questions about this template after following the instructions, try the following spaces:
- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions) - This is not an Universal Blue managed space, but is an excellent resource if you run into issues with building bootc images.

# How to Use

To get started on your first bootc image, simply read and follow the steps in the next few headings.
If you prefer instructions in video form, TesterTech created an excellent tutorial, embedded below.

[![Video Tutorial](https://img.youtube.com/vi/IxBl11Zmq5w/0.jpg)](https://www.youtube.com/watch?v=IxBl11Zmq5wE)

## Step 0: Prerequisites

These steps assume you have the following:
- A Github Account
- A machine running a bootc image (e.g. Bazzite, Bluefin, Aurora, or Fedora Atomic)
- Experience installing and using CLI programs

## Step 1: Preparing the Template

### Step 1a: Copying the Template

Select `Use this Template` on this page. You can set the name and description of your repository to whatever you would like, but all other settings should be left untouched.

Once you have finished copying the template, you need to enable the Github Actions workflows for your new repository.
To enable the workflows, go to the `Actions` tab of the new repository and click the button to enable workflows.

### Step 1b: Cloning the New Repository

Here I will defer to the much superior GitHub documentation on the matter. You can use whichever method is easiest.
[GitHub Documentation](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)

Once you have the repository on your local drive, proceed to the next step.

## Step 2: Initial Setup

### Step 2a: Creating a Cosign Key

Container signing is important for end-user security and is enabled on all Universal Blue images. By default the image builds *will fail* if you don't.

First, install the [cosign CLI tool](https://edu.chainguard.dev/open-source/sigstore/cosign/how-to-install-cosign/#installing-cosign-with-the-cosign-binary)
With the cosign tool installed, run inside your repo folder:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
```

The signing key will be used in GitHub Actions and will not work if it is password protected.

> [!WARNING]
> Be careful to *never* accidentally commit `cosign.key` into your git repo. If this key goes out to the public, the security of your repository is compromised.

Next, you need to add the key to GitHub. This makes use of GitHub's secret signing system.

<details>
    <summary>Using the Github Web Interface (preferred)</summary>

Go to your repository settings, under `Secrets and Variables` -> `Actions`
![image](https://user-images.githubusercontent.com/1264109/216735595-0ecf1b66-b9ee-439e-87d7-c8cc43c2110a.png)
Add a new secret and name it `SIGNING_SECRET`, then paste the contents of `cosign.key` into the secret and save it. Make sure it's the .key file and not the .pub file. Once done, it should look like this:
![image](https://user-images.githubusercontent.com/1264109/216735690-2d19271f-cee2-45ac-a039-23e6a4c16b34.png)
</details>
<details>
<summary>Using the Github CLI</summary>

If you have the `github-cli` installed, run:

```bash
gh secret set SIGNING_SECRET < cosign.key
```
</details>

### Step 2b: Choosing Your Base Image

To choose a base image, simply modify the line in the container file starting with `FROM`. This will be the image your image derives from, and is your starting point for modifications.
For a base image, you can choose any of the Universal Blue images or start from a Fedora Atomic system. Below this paragraph is a dropdown with a non-exhaustive list of potential base images.

<details>
    <summary>Base Images</summary>

- Bazzite: `ghcr.io/ublue-os/bazzite:stable`
- Aurora: `ghcr.io/ublue-os/aurora:stable`
- Bluefin: `ghcr.io/ublue-os/bluefin:stable`
- Universal Blue Base: `ghcr.io/ublue-os/base-main:latest`
- Fedora: `quay.io/fedora/fedora-bootc:44`

You can find more Universal Blue images on the [packages page](https://github.com/orgs/ublue-os/packages).
</details>

If you don't know which image to pick, choosing the one your system is currently on is the best bet for a smooth transition. To find out what image your system currently uses, run the following command:
```bash
sudo bootc status
```
This will show you all the info you need to know about your current image. The image you are currently on is displayed after `Booted image:`. Paste that information after the `FROM` statement in the Containerfile to set it as your base image.

### Step 2c: Changing Names

Change the `IMAGE_NAME` and `REPO_ORGANIZATION` variable inside the `image-template.env`

To commit and push all the files changed and added in step 2 into your Github repository:
```bash
git add Containerfile image-template.env cosign.pub
git commit -m "Initial Setup"
git push
```
Once pushed, go look at the Actions tab on your Github repository's page.  The green checkmark should be showing on the top commit, which means your new image is ready!

## Step 3: Switch to Your Image

From your bootc system, run the following command substituting in your Github username and image name where noted.
```bash
sudo bootc switch ghcr.io/<username>/<image_name>
```
This should queue your image for the next reboot, which you can do immediately after the command finishes. You have officially set up your custom image! See the following section for an explanation of the important parts of the template for customization.

# Repository Contents

## Containerfile

The [Containerfile](./Containerfile) defines the operations used to customize the selected image.This file is the entrypoint for your image build, and works exactly like a regular podman Containerfile. For reference, please see the [Podman Documentation](https://docs.podman.io/en/latest/Introduction.html).

## build.sh

The [build.sh](./build_files/build.sh) file is called from your Containerfile. It is the best place to install new packages or make any other customization to your system. There are customization examples contained within it for your perusal.

## build.yml

The [build.yml](./.github/workflows/build.yml) Github Actions workflow creates your custom OCI image and publishes it to the Github Container Registry (GHCR). By default, the image name will match the Github repository name.

# Building Disk Images

This template provides an out of the box workflow for creating disk images (ISO, qcow, raw) for your custom OCI image which can be used to directly install onto your machines.

This template provides a way to upload the disk images that is generated from the workflow to a S3 bucket. The disk images will also be available as an artifact from the job, if you wish to use an alternate provider. To upload to S3 we use [rclone](https://rclone.org/) which is able to use [many S3 providers](https://rclone.org/s3/).

## Setting Up ISO Builds

The [build-disk.yml](./.github/workflows/build-disk.yml) Github Actions workflow creates a disk image from your OCI image by utilizing the [bootc-image-builder](https://osbuild.org/docs/bootc/). In order to use this workflow you must complete the following steps:

1. Modify `disk_config/iso.toml` to point to your custom container image before generating an ISO image.
2. If you changed your image name from the default in `build.yml` then in the `build-disk.yml` file edit the `IMAGE_REGISTRY`, `IMAGE_NAME` and `DEFAULT_TAG` environment variables with the correct values. If you did not make changes, skip this step.
3. Finally, if you want to upload your disk images to S3 then you will need to add your S3 configuration to the repository's Action secrets. This can be found by going to your repository settings, under `Secrets and Variables` -> `Actions`. You will need to add the following
  - `S3_PROVIDER` - Must match one of the values from the [supported list](https://rclone.org/s3/)
  - `S3_BUCKET_NAME` - Your unique bucket name
  - `S3_ACCESS_KEY_ID` - It is recommended that you make a separate key just for this workflow
  - `S3_SECRET_ACCESS_KEY` - See above.
  - `S3_REGION` - The region your bucket lives in. If you do not know then set this value to `auto`.
  - `S3_ENDPOINT` - This value will be specific to the bucket as well.

Once the workflow is done, you'll find the disk images either in your S3 bucket or as part of the summary under `Artifacts` after the workflow is completed.

# Artifacthub

This template comes with the necessary tooling to index your image on [artifacthub.io](https://artifacthub.io). Use the `artifacthub-repo.yml` file at the root to verify yourself as the publisher. This is important to you for a few reasons:

- The value of artifacthub is it's one place for people to index their custom images, and since we depend on each other to learn, it helps grow the community. 
- You get to see your pet project listed with the other cool projects in Cloud Native.
- Since the site puts your README front and center, it's a good way to learn how to write a good README, learn some marketing, finding your audience, etc. 

[Discussion Thread](https://universal-blue.discourse.group/t/listing-your-custom-image-on-artifacthub/6446)

# Justfile Documentation

The `Justfile` contains various commands and configurations for building and managing container images and virtual machine images using Podman and other utilities. It is also used inside Github Actions.

## Required Utilities

Container build:
- [just](https://just.systems/man/en/introduction.html)
- [podman](https://docs.podman.io/en/latest)
- [jq](https://jqlang.org)

These are usually preinstalled on Universal Blue's Bootc Images.

Linting:
- shfmt
- shellcheck

## Environment Variables

These are all sourced from the `image-template.env` file.

- `image_name`: The name of the image (default: "image-template").
- `default_tag`: The default tag for the image (default: "latest").
- `bib_image`: The Bootc Image Builder (BIB) image (default: "quay.io/centos-bootc/bootc-image-builder:latest").

## Building The Image

All these recipes will work (with default values) without supplying any arguments to them, e.g. `just build`

### `just build`

Builds a container image using Podman.

```bash
just build $target_image $tag
```

Arguments:
- `$target_image`: The tag you want to apply to the image (default: `$image_name`).
- `$tag`: The tag for the image (default: `$default_tag`).

### Rechunking
We can flatten the layers of container images to make sure there isn't a single huge layer when your image gets published.
This does not make your image faster to download, just provides better resumability.

#### `just ostree-rechunk`
Rechunks the existing Image with [rpm-ostree](https://coreos.github.io/rpm-ostree/build-chunked-oci/)

```bash
just ostree-rechunk $target_image $tag
```

#### `just rechunk`
Rechunks the existing Image with [chunkah](https://github.com/coreos/chunkah), this is probably gonna be the default here at some point, try it out, it's cool.

```bash
just rechunk $target_image $tag
```

### Switching to the locally built image for testing

The image has to be in the containers-storage owned by root, to be able to rebase to it, see the `_rootful_load_image` recipe.

`sudo just build` and `sudo just ostree-rechunk` builds directly as root and allows you to skip the transfer to the root containers-storage.

You can rebase to all the images that are in your containers-storage:

```
sudo podman image list --filter=label=containers.bootc=1
```

See [man bootc switch](https://bootc.dev/bootc/man/bootc-switch.8.html) for more info.

```
sudo bootc switch --transport containers-storage localhost/myimage:latest
```

and reboot your system!

## Building and Running Virtual Machines and ISOs

The below commands all build QCOW2 images. To produce or use a different type of image, substitute in the command with that type in the place of `qcow2`. The available types are `qcow2`, `iso`, and `raw`.

### `just build-qcow2`

Builds a QCOW2 virtual machine image.

```bash
just build-qcow2 $target_image $tag
```

### `just rebuild-qcow2`

Rebuilds a QCOW2 virtual machine image.

```bash
just rebuild-vm $target_image $tag
```

### `just run-vm-qcow2`

Runs a virtual machine from a QCOW2 image.

```bash
just run-vm-qcow2 $target_image $tag
```

### `just spawn-vm`

Runs a virtual machine using systemd-vmspawn.

```bash
just spawn-vm rebuild="0" type="qcow2" ram="6G"
```

## File Management

### `just check`

Checks the syntax of all `.just` files and the `Justfile`.

### `just fix`

Fixes the syntax of all `.just` files and the `Justfile`.

### `just clean`

Cleans the repository by removing build artifacts.

### `just lint`

Runs shell check on all Bash scripts.

### `just format`

Runs shfmt on all Bash scripts.

## Additional resources

For additional driver support, ublue maintains a set of scripts and container images available at [ublue-akmod](https://github.com/ublue-os/akmods). These images include the necessary scripts to install multiple kernel drivers within the container (Nvidia, OpenRazer, Framework...). The documentation provides guidance on how to properly integrate these drivers into your container image.

## Community Examples

These are images derived from this template (or similar enough to this template). Reference them when building your image!

- [m2Giles' OS](https://github.com/m2giles/m2os)
- [bOS](https://github.com/bsherman/bos)
- [Homer](https://github.com/bketelsen/homer/)
- [Amy OS](https://github.com/astrovm/amyos)
- [VeneOS](https://github.com/Venefilyn/veneos)
