## About
**Wikiman** is an offline search engine for manual pages, Arch Wiki, Gentoo Wiki and other documentation.

Wikiman provides an easy interface for browsing documentation without the need to be exact and connected to the internet.
This is achieved by utilizing full text search for wikis, partial name and description matching for man pages,
and fuzzy filtering for search results.

By default, Wikiman only searches system's manual pages.
Follow [these](#installing-additional-sources) instructions to enable optional sources.


## Demonstration

![Demo](demo.gif)


## Installation

### Arch Linux ([AUR](https://aur.archlinux.org/packages/wikiman/))
```bash
yay -Syu wikiman

# Optional: Enable Arch Wiki
yay -Syu arch-wiki-docs
mkdir -p ~/.config/wikiman
echo 'sources = man, arch' >> ~/.config/wikiman/wikiman.conf
```

If you are running Manjaro, package `arch-wiki-docs` is not in official repositories.
Follow [these](#installing-additional-sources) instructions to download it.

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

### Manual installation

Dependencies: `man`, `fzf-compatible fuzzy finder`, `ripgrep`, `awk`, `w3m`

```bash
# Install latest stable version of wikiman
git clone 'https://github.com/filiparag/wikiman'
cd ./wikiman
git checkout $(git tag | tail -1)
make
sudo make install
```

### Installing additional sources

Due to their large size, wikis don't come bundled with Wikiman.
If you want to use them, you can download their snapshots using following commands.

User source modules are located in `~/.config/wikiman/sources/`,
and system-wide sources are in `/usr/share/wikiman/sources/`.
If there is a name collision, user modules have priority over system-wide sources.

Available optional sources are:

- Arch Wiki (`arch`)
- Gentoo Wiki (`gentoo`)
- FreeBSD Documentation (`fbsd`)

```bash
# Download latest Makefile
curl -L 'https://raw.githubusercontent.com/filiparag/wikiman/master/Makefile' -o 'wikiman-makefile'

# Example: install Arch Wiki
sudo make -f ./wikiman-makefile source-arch
```

After installation, enable them by adding them to sources variable in the [configuration file](#configuration).

## Usage

Usage: `wikiman [OPTION]... [KEYWORD]...`

If no keywords are provided, show all pages.

### Options:

- `-l` search language(s)

    Default: *en*

- `-s` sources to use
 
    Default: *man*

- `-f` fuzzy finder to use

    Default: *fzf*

- `-q` enable quick search mode

- `-p` disable quick result preview

- `-k` keep open after viewing a result

- `-H` viewer for HTML pages

    Default: *w3m*

- `-R` print raw output

- `-S` list available sources and exit

- `-h` display this help and exit


## Configuration

User configuration file is located at `~/.config/wikiman/wikiman.conf`,
and fallback system-wide configuration is `/etc/wikiman.conf`.

If you have set the *XDG_CONFIG_HOME* environment variable, user configuration
will be looked up from there instead.

Example configuration file:

```ini
# Sources (if empty, use all available)
sources = man, arch

# Quick search mode (only by title)
quick_search = true

# Raw output (for developers)
raw_output = false

# Manpages language(s)
man_lang = en, pt, pt_BR

# Wiki language(s)
wiki_lang = zh-CN

# Show previews in TUI
tui_preview = false

# Keep open after viewing a result
tui_keep_open = true

# Viewer for HTML pages
tui_html = xdg-open

# Fuzzy finder
fuzzy_finder = fzf
```

To list available languages, run these commands:

```bash
# Man pages (excluding English)
find '/usr/share/man' -maxdepth 1 -type d -not -name 'man*' -printf '%P '

# Arch Wiki
find '/usr/share/doc/arch-wiki/html' -maxdepth 1 -type d -printf '%P '

# FreeBSD Documentation
find '/usr/share/doc/freebsd-docs' -maxdepth 1 -type d -printf '%P '
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
- short description in the pull request's body

Other improvements are also welcome!
