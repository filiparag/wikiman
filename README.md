## About
**wikiman** is an offline search engine for ArchWiki and manual pages combined.

Wikiman provides an easy interface for browsing documentation without the need to be exact and connected to the internet.
This is achieved by utilizing full text search for ArchWiki, partial name and description matching for man pages,
and fuzzy filtering for search results.


## Demonstration

![Demo](demo.gif)


## Installation

### Arch Linux (AUR)
```bash
yay -Sy wikiman
```

### Ubuntu / Debian

Download latest *.deb* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
sudo dpkg -i wikiman-*.deb
```

### Fedora

Download latest *.rpm* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
sudo dnf install wikiman-*.rpm
```

### Installing Arch Wiki Docs

You can install the snapshot from this repository, or compile it yourself using [this utility](https://github.com/lahwaacz/arch-wiki-docs).

```bash
curl -L -O 'https://github.com/filiparag/wikiman/releases/download/2.4/arch-linux-docs_20200527-1.tar.xz'
sudo tar zxf 'arch-linux-docs_20200527-1.tar.xz' -C /
```

### Manual installation

Dependencies: `man`, `fzf`, `ripgrep`, `awk`, `w3m`

```bash
# Install latest stable version of wikiman
git clone 'https://github.com/filiparag/wikiman'
cd 'wikiman'
git checkout $(git tag | tail -1)
make
sudo make install

# Download latest Arch Wiki Docs snapshot
sudo make archwiki
```

## Usage

Usage: `wikiman [OPTION]... [KEYWORD]...`

### Options:

- `-l` search language(s)

    Default: *en*

- `-s` sources to use
 
    Default: *man, archwiki*

- `-q` enable quick search mode

- `-p` disable quick result preview

- `-H` viewer for HTML pages

    Default: *w3m*

- `-R` print raw output

- `-S`  list available sources and exit

- `-h` display this help and exit


## Configuration

User configuration file is located at `~/.config/wikiman/wikiman.conf`,
and fallback system-wide configuration is `/etc/wikiman.conf`.

If you have set the *XDG_CONFIG_HOME* environment variable, user configuration
will be looked up from there instead.

Example configuration file:

```ini
# Sources
sources = archwiki

# Quick search mode (only by title)
quick_search = false

# Raw output (for developers)
raw_output = false

# Manpages language(s)
man_lang = en, pt, pt_BR

# ArchWiki language(s)
wiki_lang = zh-CN

# Show previews in TUI
tui_preview = false

# Viewer for HTML pages
tui_html = xdg-open
```

To list available languages, run these commands:

```bash
# Man pages (excluding English)
find '/usr/share/man' -maxdepth 1 -type d -not -name 'man*' -printf '%P '

# Arch Wiki
find '/usr/share/doc/arch-wiki/html' -maxdepth 1 -type d -printf '%P '
```