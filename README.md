## About
**Wikiman** is an offline search engine for manual pages, Arch Wiki, Gentoo Wiki and other documentation.

Wikiman provides an easy interface for browsing documentation without the need to be exact and connected to the internet.
This is achieved by utilizing full text search for wikis, partial name and description matching for man pages,
and fuzzy filtering for search results.

By default, Wikiman only searches system's manual pages.
Follow [these](#additional-documentation-sources) instructions to enable optional sources.


## Demonstration

![Demo](demo.gif)


## Installation

### Arch Linux / Manjaro ([AUR](https://aur.archlinux.org/packages/wikiman/))
```bash
yay -Syu wikiman

# Optional: Enable Arch Wiki
yay -Syu arch-wiki-docs
```
If you are running Manjaro, package `arch-wiki-docs` is not in official repositories.
Follow [these](#installing-additional-sources) instructions to download it.

Or download latest *.pkg.tar.zst* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.
```bash
sudo pacman -U wikiman*.pkg.tar.zst
```

### Ubuntu / Debian

Download latest *.deb* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
sudo apt update
sudo apt install ./wikiman*.deb
```

### Fedora / openSUSE

Download latest *.rpm* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
# Fedora
sudo dnf install wikiman*.rpm

# openSUSE (skip signature verification)
sudo zypper in wikiman*.rpm
```

### FreeBSD

Install [textproc/wikiman](https://www.freshports.org/textproc/wikiman) from the Ports Collection:

```bash
portsnap auto
cd /usr/ports/textproc/wikiman
make install
```

Or download latest *.txz* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
pkg install wikiman*.txz
```

### Manual installation for Linux and BSD

Dependencies: `man`, `fzf`, `ripgrep`, `awk`, `w3m`, `coreutils`

```bash
# Clone from GitHub
git clone 'https://github.com/filiparag/wikiman'
cd ./wikiman

# Switch to latest stable release (optional)
git checkout $(git describe --tags | cut -d'-' -f1)

# Available targets: all, core, widgets, completions, config, docs
make all

# Only for BSD users: install to /usr/local instead of /usr
make local

# Install Wikiman
sudo make install
```

Wikiman uses GNU `find` and `awk`, so BSD users have to install `findutils` and `gawk`.


## Additional documentation sources

Due to their large size, wikis don't come bundled with Wikiman.
If you want to use them, you can download their snapshots using following commands.

User source modules are located in `~/.config/wikiman/sources/`,
and system-wide sources are in `/usr/share/wikiman/sources/`.
If there is a name collision, user modules have priority over system-wide sources.

Available optional sources are:

- Arch Wiki (`arch`)
- Gentoo Wiki (`gentoo`)
- FreeBSD Documentation (`fbsd`)
- TLDR Pages (`tldr`)

```bash
# Download latest Makefile
curl -L 'https://raw.githubusercontent.com/filiparag/wikiman/master/Makefile' -o 'wikiman-makefile'

# Example for Linux: install Arch Wiki
make -f ./wikiman-makefile source-arch
sudo make -f ./wikiman-makefile source-install
sudo make -f ./wikiman-makefile clean

# Example for BSD: install FreeBSD Documentation
make -f ./wikiman-makefile source-fbsd
sudo make -f ./wikiman-makefile source-install
sudo make -f ./wikiman-makefile clean
```

After installation, they should be enabled automatically if 
`sources` [configuration](#configuration) variable is empty. 

To verify active sources, run:

```bash
wikiman -S
```

### Compiling a snapshot (database build scripts)

In [`build/`](https://github.com/filiparag/wikiman/tree/master/build) directory there are scripts
for manual snapshot compilation. These scripts can have external dependencies and are not 
recommended to be run by end users, but by Wikiman maintainers. Your mileage may vary.

## Usage

Usage: `wikiman [OPTION]... [KEYWORD]...`

If no keywords are provided, show all pages.

### Options:

- `-l` search language(s)

    Default: *en*

- `-s` sources to use
 
    Default: (all available)

- `-f` fuzzy finder to use

    Default: *fzf*

- `-q` enable quick search mode

- `-a` enable *AND* operator mode

- `-p` disable quick result preview

- `-k` keep open after viewing a result

- `-c` show source column

- `-H` viewer for HTML pages

    Default: *w3m*

- `-R` print raw output

- `-S` list available sources and exit

- `-W` print widget code for specified shell and exit

- `-v` print version and exit

- `-h` display this help and exit

### Shell keybind widgets

Wikiman can be launched using a shell key binding (default: `Ctrl+F`).
Current command line buffer will be used as a search query.

Add appropriate line from below to your `.bashrc`-like 
configuration file to make the key binding permanent.

```bash
# bash
source /usr/share/wikiman/widgets/widget.bash

# fish
source /usr/share/wikiman/widgets/widget.fish

# zsh
source /usr/share/wikiman/widgets/widget.zsh
```

## Configuration

User configuration file is located at `~/.config/wikiman/wikiman.conf`,
and fallback system-wide configuration is `/etc/wikiman.conf`.

If you have set the *XDG_CONFIG_HOME* environment variable, user configuration
will be looked up from there instead.

Example configuration file:

```ini
# Sources (if empty, use all available)
sources = man, arch

# Fuzzy finder
fuzzy_finder = sk

# Quick search mode (only by title)
quick_search = true

# Raw output (for developers)
raw_output = false

# Manpages language(s)
man_lang = en, pt

# Wiki language(s)
wiki_lang = zh-CN

# Show previews in TUI
tui_preview = false

# Keep open after viewing a result
tui_keep_open = true

# Show source column
tui_source_column = true

# Viewer for HTML pages
tui_html = xdg-open
```

To list available languages, run these commands:

```bash
# Man pages (excluding English)
find '/usr/share/man' -maxdepth 1 -type d -not -name 'man*' -printf '%P '

# Arch Wiki
find '/usr/share/doc/arch-wiki/html' -maxdepth 1 -type d -printf '%P '

# FreeBSD Documentation
find '/usr/share/doc/freebsd-docs' -maxdepth 1 -type d -printf '%P '

# TLDR Pages
find '/usr/share/doc/tldr-pages' -maxdepth 1 -type d -printf '%P '
```


## Custom sources

Wikiman is designed to be extensible: each source has it's module in `sources/` directory.

Source modules are POSIX compliant shell scripts. Wikiman calls their `search` function whichs 
reads `$query` and configuration variables, and prints results to *STDOUT*.
variable with rows formatted as `NAME\tLANG\tSOURCE\tPATH`.

- `NAME`    title of the page
- `LANG`    two letter language code (can include locale)
- `SOURCE`  source name
- `PATH`    path to HTML file

When listing available sources, Wikiman will call module's `info` funcion which prints
name, state, number of pages and path of the source.

## Contributions

If you create a source module useful to the general public, please share it using a 
[pull request](https://github.com/filiparag/wikiman/pulls). Your pull request should contain:

- module script file `sources/your-source.sh`
- Makefile recipe `your-source`
- installable snapshot of the source database `your-source-TIMESTAMP.tar.xz`
- build script for the database snapshot `build/your-source.sh`
- short description in the pull request's body

Other improvements are also welcome!
