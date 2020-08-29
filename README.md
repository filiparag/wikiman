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

### Generic instructions
```bash
git clone 'https://github.com/filiparag/wikiman'
cd 'wikiman'
sudo install -Dm 755 'wikiman.sh' '/usr/bin/wikiman'
sudo install -Dm 644 'wikiman.1.man' '/usr/share/man/man1/wikiman.1'
sudo install -Dm 644 -t '/usr/share/licenses/wikiman' 'LICENSE'
sudo install -Dm 644 -t '/usr/share/doc/wikiman' 'README.md'
```
Download [Arch Wiki Docs](https://github.com/lahwaacz/arch-wiki-docs) and install
them to `/usr/share/doc/arch-wiki/html/` on your system.

Dependencies: `man, fzf, ripgrep, awk, w3m`

## Usage

Usage: `wikiman [OPTION]... [KEYWORD]...`

With no *KEYWORD*, list all available results.

### Options:

- `-l` search language(s)

    Default: en

- `-s` sources to use
 
    Default: man, archwiki

- `-p` quick result preview
 
    Default: true

- `-H` viewer for HTML pages

    Default: w3m

- `-h`  display this help and exit"