#!/usr/bin/env bash

export XZ_OPT=-e9T0

echo 'Installing tools'
pacman -Sy --noconfirm rdfind wget git base-devel moreutils parallel

echo 'Building tools'
git clone --depth 1 https://aur.archlinux.org/pup-bin.git ./pup
cd ./pup || exit 1
chown -R nobody .
chage -E -1 nobody
su nobody -s /bin/sh -c 'makepkg -sc --noconfirm'
pacman -U --noconfirm ./pup-bin-*.pkg.tar.zst || exit 1

mkdir -p ./fbsd
cd ./fbsd || exit 1
dir="$(pwd)"

echo 'Downloading FreeBSD docs'
wget -r 'ftp://ftp.freebsd.org/pub/FreeBSD/doc/' -A .tar.gz
mv ./ftp.freebsd.org/pub/FreeBSD/doc ./
rm -rf ./ftp.freebsd.org

echo 'Unpacking pages'
find "$dir/doc" -type f -name '*.tar.gz' | parallel --will-cite \
    "tar -xf {} -C {//} && rm -f {}"

cd "$dir" || exit 1
mv "$dir/doc" "$dir/freebsd-docs"

echo 'Deduplicating assets'
cd "$dir/freebsd-docs" || exit 1
rdfind \
    -makehardlinks false \
    -makesymlinks true \
    -makeresultsfile false \
    .
find . -type l | while read -r l; do
    target="$(realpath "$l")"
    ln -fs "$(realpath --relative-to="$(dirname "$(realpath -s "$l")")" "$target")" "$l"
done

echo 'Page post-processing'
find "$dir/freebsd-docs" -type f -name '*.html' -print0 | parallel -0 --will-cite \
    "pup 'head, nav#TableOfContents, div.book, div.article' --pre < {} | sponge {}"

echo 'Compressing data'
cd "$dir" || exit 1
archive="freebsd-docs_$(date +'%Y%m%d').source.tar.xz"
tar -cJf "/release/$archive" freebsd-docs
echo "Generated $(du -h "/release/$archive" | cut -f1) FreeBSD docs archive"

echo 'Testing archive contents'
pagecount="$(tar -tf "/release/$archive" | grep -c '\.html$')"
if [ "$pagecount" -lt 1000 ]; then
    echo 'Error: archive page count is too low'
    exit 1
else
    echo "Archive contains ${pagecount} HTML pages"
fi

echo 'Done'
