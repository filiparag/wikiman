#!/usr/bin/env bash

export XZ_OPT=-e9T0

echo 'Downloading Arch Wiki package'
pacman -Syw --noconfirm arch-wiki-docs

echo 'Extracting data'
tar --use-compress-program=unzstd -xf /var/cache/pacman/pkg/arch-wiki-docs-*.pkg.tar.zst usr/share/doc/arch-wiki/html/

echo 'Compressing data'
archive="arch-wiki_$(date +'%Y%m%d').source.tar.xz"
tar -cJf "/release/$archive" usr/share/doc/arch-wiki/html
echo "Generated $(du -h "/release/$archive" | cut -f1) Arch Wiki archive"

echo 'Testing archive contents'
pagecount="$(tar -tf "/release/$archive" | grep -c '\.html$')"
if [ "$pagecount" -lt 5000 ]; then
    echo 'Error: archive page count is too low'
    exit 1
else
    echo "Archive contains ${pagecount} HTML pages"
fi

echo 'Done'
