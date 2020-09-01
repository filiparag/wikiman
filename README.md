## About
**Wikiman** is an offline search engine for Arch Wiki, Gentoo Wiki and manual pages.

Wikiman provides an easy interface for browsing documentation without the need to be exact and connected to the internet.
This is achieved by utilizing full text search for wikis, partial name and description matching for man pages,
and fuzzy filtering for search results.

By default, Wikiman only searches manual pages.
Follow [these](#installing-arch-wiki-and-gentoo-wiki) instructions to enable wikis.


## Demonstration

![Demo](demo.gif)


## Installation

### Arch Linux ([AUR](https://aur.archlinux.org/packages/wikiman/))
```bash
yay -Sy wikiman

# Optional: Enable Arch Wiki
yay -Sy arch-wiki-docs
mkdir -p ~/.config/wikiman
echo 'sources = man, arch' >> ~/.config/wikiman/wikiman.conf
```

### Ubuntu / Debian

Download latest *.deb* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
sudo apt update
sudo apt install man fzf ripgrep gawk w3m
sudo dpkg -i wikiman-*.deb
```

### Fedora

Download latest *.rpm* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
sudo dnf install wikiman-*.rpm
```

### Installing Arch Wiki and Gentoo Wiki

Due to their large size, wikis don't come bundled with Wikiman.
If you want to use them, you can download their snapshots using following commands.

```bash
# Arch Wiki
curl -L -O 'https://github.com/filiparag/wikiman/releases/download/2.4/arch-linux-docs_20200527-1.tar.xz'
sudo tar zxf 'arch-linux-docs_20200527-1.tar.xz' -C /

# Gentoo Wiki
curl -L -O 'https://github.com/filiparag/wikiman/releases/download/2.7/gentoo-wiki_20200831-1.tar.xz'
sudo tar zxf 'gentoo-wiki_20200831-1.tar.xz' -C /
```

After installation, enable them by adding them to sources variable in the [configuration file](#configuration).

```ini
sources = man, arch, gentoo
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
sudo make arch-wiki

# Download latest Gentoo Wiki Docs snapshot
sudo make gentoo-wiki
```

## Usage

Usage: `wikiman [OPTION]... [KEYWORD]...`

### Options:

- `-l` search language(s)

    Default: *en*

- `-s` sources to use
 
    Default: *man*

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
sources = man, arch, gentoo

# Quick search mode (only by title)
quick_search = false

# Raw output (for developers)
raw_output = false

# Manpages language(s)
man_lang = en, pt, pt_BR

# Wiki language(s)
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


## Custom sources

Wikiman is designed to be extensible: each source has it's module in `sources/` directory.

Source modules are POSIX compliant shell scripts. Wikiman calls their `search` function whichs 
reads `$query` and configuration variables, and puts ordered search results into `$results` 
variable with rows formatted as `NAME\tLANG\tSOURCE\tPATH`.

- `NAME`    title of the page
- `LANG`    two letter language code (can include locale)
- `SOURCE`  source name
- `PATH`    path to HTML file


## Contributions

If you create a source module useful to the general public, please share it using a 
[pull request](https://github.com/filiparag/wikiman/pulls). Your pull request should contain:

- module script file `sources/your-source.sh`
- Makefile recipe `your-source`
- installable snapshot of the source database `your-source-TIMESTAMP.tar.xz`
- short description in the pull request's body

Other improvements are also welcome!
