#!/usr/bin/env bash

export XZ_OPT=-e9T0

echo 'Installing tools'
pacman -Sy --noconfirm curl git ripgrep zim-tools base-devel

echo 'Building tools'
git clone --depth 1 https://aur.archlinux.org/xq-bin.git ./xq
cd ./xq || exit 1
chown -R nobody .
chage -E -1 nobody
pacman -S --noconfirm help2man
su nobody -s /bin/sh -c 'makepkg -sc --noconfirm'
pacman -U --noconfirm ./xq-bin-*.pkg.tar.zst || exit 1

cd / || exit 1
mkdir -p ./devdocs
cd ./devdocs || exit 1
dir="$(pwd)"

echo 'Retrieving latest snapshot list'
kiwix='https://download.kiwix.org/zim/'
latest_snapshots="$(
    curl "$kiwix/devdocs/" | \
    xq -m -q 'a' | sort -r | awk -F '_' -v stub="$kiwix/devdocs/" \
    '/^devdocs_en_/&&/\.zim$/ {
        if (!seen[$3]) {
            ++seen[$3];
            print $3 "\t" stub $0;
        }
    }' | sort
)"

echo "Found $(echo "$latest_snapshots" | wc -l) documentation snapshots"

mkdir -p "$dir/zim"
while IFS=$'\t' read -r name url || [[ -n $line ]]; do

    echo "Downloading snapshot for '$name'"
    curl -L "$url" -o "$dir/zim/$name.zim"

    echo "Processing '$name'"
    mkdir -p "$dir/docs/$name"
    zimdump dump --dir "$dir/docs/$name" "$dir/zim/$name.zim"
    rg -i -l --null --null-data '\<head\>' "$dir/docs/$name" | xargs -0 -I {} mv {} {}.html

done < <(echo "$latest_snapshots")

cd "$dir" || exit 1
mkdir -p "$dir/usr/share/doc/devdocs"
mv "$dir/docs/"* "$dir/usr/share/doc/devdocs"

echo 'Compressing data'
cd "$dir" || exit 1
archive="devdocs_$(date +'%Y%m%d').source.tar.xz"
tar -cJf "/release/$archive" usr/share/doc/devdocs
echo "Generated $(du -h "/release/$archive" | cut -f1) DevDocs archive"

echo 'Testing archive contents'
pagecount="$(tar -tf "/release/$archive" | grep -c '\.html$')"
if [ "$pagecount" -lt 150000 ]; then
    echo 'Error: archive page count is too low'
    exit 1
else
    echo "Archive contains ${pagecount} HTML pages"
fi

echo 'Done'
