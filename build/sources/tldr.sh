#!/usr/bin/env bash

export XZ_OPT=-e9T0

echo 'Installing tools'
pacman -Sy --noconfirm curl git discount

mkdir -p ./tldr
cd ./tldr || exit 1
dir="$(pwd)"

echo 'Downloading TLDR Pages'
git clone --depth 1 --single-branch --branch main https://github.com/tldr-pages/tldr ./doc
cd "$dir/doc" || exit 1

echo 'Restructuring'
find "$dir/doc" -maxdepth 1 -mindepth 1 -not -name 'pages*' -exec rm -rf {} \;
rm -rf "$dir/doc/pages.hbs"
mv "$dir/doc/pages" "$dir/doc/en"
for lang in $(find "$dir/doc" -maxdepth 1 -mindepth 1 -name 'pages.*' -printf '%P '); do
    l="$(echo "$lang" | cut -d'.' -f2)"
    mv "$dir/doc/$lang" "$dir/doc/$l"
done

echo "Rendering HTML for $(find "$dir/doc" -name '*.md' | wc -l) pages"
find . -type f -name "* *.md" -exec rename ' ' '' {} \;
for md in $(find "$dir/doc" -name '*.md'); do
    realpath --relative-to "$dir/doc" "$md" >/dev/null
    ht="$(echo "$md" | cut -d'.' -f1).html"
    markdown "$md" > "$ht"
    rm "$md"
done

mkdir -p "$dir/usr/share/doc"
mv "$dir/doc" "$dir/usr/share/doc/tldr-pages"
cd "$dir" || exit 1

echo 'Compressing data'
archive="tldr-pages_$(date +'%Y%m%d').source.tar.xz"
tar -cJf "/release/$archive" usr/share/doc/tldr-pages
echo "Generated $(du -h "/release/$archive" | cut -f1) TLDR Pages archive"

echo 'Testing archive contents'
pagecount="$(tar -tf "/release/$archive" | grep -c '\.html$')"
if [ "$pagecount" -lt 20000 ]; then
    echo 'Error: archive page count is too low'
    exit 1
else
    echo "Archive contains ${pagecount} HTML pages"
fi

echo 'Done'
