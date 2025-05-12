#!/bin/bash

export XZ_OPT=-e9T0

echo 'Downloading Arch Wiki package'
pacman -Syw --noconfirm arch-wiki-docs

echo 'Extracting data'
tar --use-compress-program=unzstd -xf /var/cache/pacman/pkg/arch-wiki-docs-*.pkg.tar.zst usr/share/doc/arch-wiki/html/

echo 'Compressing data'
archive="arch-wiki_$(date +'%Y%m%d').tar.xz"
tar -cJf "/release/$archive" usr/share/doc/arch-wiki/html

echo 'Done'
