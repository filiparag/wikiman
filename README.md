## About

**Wikiman** is a universal offline documentation search engine. It can browse system manual pages, [tldr-pages](https://github.com/tldr-pages/tldr), the [ArchWiki](https://wiki.archlinux.org/), [Gentoo Wiki](https://wiki.gentoo.org/wiki/), [FreeBSD documentation](https://docs.freebsd.org/), and many other sources curated by [DevDocs](https://devdocs.io/).

It provides an easy interface for browsing documentation without the need to be exact and connected to the internet. This is achieved by utilizing full-text search for wikis, partial name and description matching for man pages, and fuzzy filtering for search results.

> [!TIP]
> By default, Wikiman only searches manual pages. Follow [these instructions](#additional-documentation-sources) to download and enable optional documentation sources.

![Demo](demo.gif)

## Installation

### Arch Linux

Install from Arch Linux's [extra](https://archlinux.org/packages/extra/any/wikiman/) repository:

```bash
pacman -S wikiman

# Optional: Enable ArchWiki
pacman -S arch-wiki-docs
```

If you are running Manjaro or another Arch-based distribution, download the latest _.pkg.tar.zst_ package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab, and follow [these](https://github.com/filiparag/wikiman#installing-additional-sources) instructions to add ArchWiki as a source.

```sh
sudo pacman -U wikiman*.pkg.tar.zst
```

### Ubuntu / Debian

Download latest _.deb_ package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
sudo apt update
sudo apt install ./wikiman*.deb
```

### Fedora / openSUSE

Download latest _.rpm_ package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

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

Or download latest _.txz_ package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
pkg install wikiman*.txz
```

### Manual installation for Linux and BSD

Dependencies: `man`, `fzf`, `ripgrep`, `awk`, `w3m`, `coreutils`, `parallel`

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

Currently available optional sources are:

- ArchWiki (`arch`)
- DevDocs (`devdocs`)
- FreeBSD Documentation (`fbsd`)
- Gentoo Wiki (`gentoo`)
- TLDR Pages (`tldr`)

Due to their large size, wikis don't come bundled with Wikiman. If you want to use them, you can download their latest snapshots using following commands.

```bash
# Download latest Makefile
curl -L 'https://raw.githubusercontent.com/filiparag/wikiman/master/Makefile' -o 'wikiman-makefile'

# Example for Linux: install ArchWiki and TLDR pages
make -f ./wikiman-makefile source-arch source-tldr
sudo make -f ./wikiman-makefile source-install
sudo make -f ./wikiman-makefile clean

# Example for BSD: install FreeBSD docs and TLDR pages
make -f ./wikiman-makefile source-fbsd source-tldr
make -f ./wikiman-makefile source-local # moves files from /usr to /usr/local
sudo make -f ./wikiman-makefile source-install
sudo make -f ./wikiman-makefile clean
```

After installation, they should be enabled automatically if `sources` [configuration](#configuration) variable is empty.

To verify active sources, run:

```bash
wikiman -S
```

> [!NOTE]
> DevDocs source provides access to documentation for hundreds of unrelated individual projects, organized into separate "books." To choose which books are active, prepend your Wikiman queries with `=book` (eg. `=c,cpp,python`). By default, this source returns no results, as no books are selected automatically.

## Usage

Usage: `wikiman [OPTION]... [KEYWORD]...`

If no keywords are provided, show all pages.

### Options:

- `-l` search language(s)

  Default: _en_

- `-s` sources to use

  Default: (all available)

- `-f` fuzzy finder to use

  Default: _fzf_

- `-q` enable quick search mode

- `-a` enable _AND_ operator mode

- `-p` disable quick result preview

- `-k` keep open after viewing a result

- `-c` show source column

- `-H` viewer for HTML pages

  Default: _w3m_

- `-R` print raw output

- `-S` list available sources and exit

- `-W` print widget code for specified shell and exit

- `-v` print version and exit

- `-h` display this help and exit

### Shell keybind widgets

Wikiman can be launched using a shell key binding (default: `Ctrl+F`). Current command line buffer will be used as a search query.

Add appropriate line from below to your `.bashrc`-like configuration file to make the key binding permanent.

```bash
# bash
source /usr/share/wikiman/widgets/widget.bash

# fish
source /usr/share/wikiman/widgets/widget.fish

# zsh
source /usr/share/wikiman/widgets/widget.zsh
```

## Configuration

User configuration file is located at `~/.config/wikiman/wikiman.conf`, and fallback system-wide configuration is `/etc/wikiman.conf`.

If you have set the _XDG_CONFIG_HOME_ environment variable, user configuration will be looked up from there instead.

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

# ArchWiki
find '/usr/share/doc/arch-wiki/html' -maxdepth 1 -type d -printf '%P '

# FreeBSD Documentation
find '/usr/share/doc/freebsd-docs' -maxdepth 1 -type d -printf '%P '

# TLDR Pages
find '/usr/share/doc/tldr-pages' -maxdepth 1 -type d -printf '%P '
```

## Custom sources

Wikiman is designed to be extensible: each source has it's module in `sources/` directory. These modules are loaded as needed during runtime.

Source modules are POSIX compliant shell scripts. Wikiman calls their `search` function which reads `$query` and configuration variables, and prints results to _STDOUT_. variable with rows formatted as `NAME\tLANG\tSOURCE\tPATH`.

- `NAME` title of the page
- `LANG` two letter language code (can include locale)
- `SOURCE` source name
- `PATH` path to HTML file

When listing available sources, Wikiman will call module's `info` funcion which prints name, state, number of pages and path of the source.

## Contributions

If you create a source module useful to the general public, please share it using a [pull request](https://github.com/filiparag/wikiman/pulls). Your pull request should contain:

- module script file `sources/your-source.sh`
- Makefile recipe `source-your-source`
- build script for the database snapshot `build/sources/your-source.sh`
- demo snapshot of the source database `your-source-TIMESTAMP.source.tar.xz` (optional)
- short description in the pull request's body

Other improvements are also welcome!
