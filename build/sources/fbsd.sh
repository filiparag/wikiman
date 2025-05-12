#!/bin/sh

export XZ_OPT=-e9T0

echo 'Installing tools'
pacman -Sy --noconfirm rdfind wget

mkdir -p ./fbsd
cd ./fbsd || exit 1
dir="$(pwd)"

echo 'Downloading FreeBSD Wiki'
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
rdfind -makehardlinks false -makesymlinks true -makeresultsfile false "$dir/usr/share/doc/freebsd-docs"

echo 'Compressing data'
archive="freebsd-docs_$(date +'%Y%m%d').tar.xz"
tar -cJf "/release/$archive" usr/share/doc/freebsd-docs

echo 'Done'
