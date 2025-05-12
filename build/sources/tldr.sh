#!/bin/sh

# Targeted for Arch Linux

paru -S discount --noconfirm

mkdir -p ./tldr
cd ./tldr

dir="$(pwd)"

git clone https://github.com/tldr-pages/tldr ./doc
cd ./doc || exit 1

find "$dir/doc" -maxdepth 1 -mindepth 1 -not -name 'pages*' -exec rm -rf {} \;

rm -rf "$dir/doc/pages.hbs"

mv "$dir/doc/pages" "$dir/doc/en"

for lang in $(find "$dir/doc" -maxdepth 1 -mindepth 1 -name 'pages.*' -printf '%P '); do
    l="$(echo "$lang" | cut -d'.' -f2)"
    mv "$dir/doc/$lang" "$dir/doc/$l"
done

find . -type f -name "* *.md" -exec rename ' ' '' {} \;

for md in $(find "$dir/doc" -name '*.md'); do
    realpath --relative-to "$dir/doc" "$md"
    ht="$(echo "$md" | cut -d'.' -f1).html"
    markdown "$md" > "$ht"
    rm "$md"
done

mkdir -p "$dir/usr/share/doc"
mv "$dir/doc" "$dir/usr/share/doc/tldr-pages"

cd "$dir"

tar -cjf "../tldr-pages_$(date +'%Y%m%d').tar.xz" "usr/share/doc/tldr-pages"

cd ..

rm -rf "$dir"