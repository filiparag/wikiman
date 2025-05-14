#!/usr/bin/env bash

export XZ_OPT=-e9T0

echo 'Installing tools'
pacman -Sy --noconfirm rdfind wget git base-devel moreutils

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
for f in $(find "$dir/doc" -type f -name '*.tar.gz'); do
    d="$(dirname "$f")"
    cd "$d" || exit 1
    tar -xf "$f"
    rm -f "$f"
done

cd "$dir" || exit 1
mkdir -p "$dir/usr/share/doc"
mv "$dir/doc" "$dir/usr/share/doc/freebsd-docs"

echo 'Deduplicating assets'
cd "$dir/usr/share/doc/freebsd-docs" || exit 1
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
find "$dir/usr/share/doc/freebsd-docs" -type f -name '*.html' -print0 | xargs -0 --no-run-if-empty -I{} sh -c "cat \"{}\" | pup 'head, nav#TableOfContents, div.book, div.article' --pre | sponge \"{}\""

echo 'Compressing data'
cd "$dir" || exit 1
archive="freebsd-docs_$(date +'%Y%m%d').source.tar.xz"
tar -cJf "/release/$archive" usr/share/doc/freebsd-docs
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
