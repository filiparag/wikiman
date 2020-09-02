#!/bin/sh

mkdir -p ./fbsd
cd ./fbsd

wget -r 'ftp://ftp.freebsd.org/pub/FreeBSD/doc/' -A .html-split.tar.bz2

mv ./ftp.freebsd.org/pub/FreeBSD/doc ./
rm -rf ./ftp.freebsd.org

dir="$(pwd)"

cd "$dir/doc"

remove_list=''
for f in $(find . -maxdepth 1 -mindepth 1 -type d -printf '%P\n'); do

    echo "$remove_list" | grep -q "$f" && continue

    n="$(echo "$f" | cut -d'.' -f1)"
    encodings="$(find . -maxdepth 1 -mindepth 1 -type d -printf '%P\n' | grep "^$n\.")"

    if [ -d "$dir/doc/$n.UTF-8" ]; then
        keep="$n.UTF-8"
    else
        keep="$(echo "$encodings" | head -n 1)"
    fi

    remove_list="$remove_list $(
        echo "$encodings" | grep -v "$keep"
    )"

    mv "$keep" "$n"

done
eval "rm -rf $remove_list"

for f in $(find "$dir/doc" -type f -name '*.tar.bz2'); do
    d="$(dirname "$f")"
    cd "$d"
    tar -xjf "$f"
    rm -f "$f"
done

cd "$dir"

mkdir -p "$dir/usr/share/doc"
mv "$dir/doc" "$dir/usr/share/doc/freebsd-docs"

tar -cjf "../freebsd-docs_$(date +'%Y%m%d').tar.xz" "usr/share/doc/freebsd-docs"

cd ..

rm -rf "$dir"