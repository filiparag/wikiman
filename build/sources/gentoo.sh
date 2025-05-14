#!/usr/bin/env bash

export XZ_OPT=-e9T0

echo 'Installing tools'
pacman -Sy --noconfirm curl wget git base-devel moreutils

echo 'Building tools'
git clone --depth 1 https://aur.archlinux.org/pup-bin.git ./pup
cd ./pup || exit 1
chown -R nobody .
chage -E -1 nobody
su nobody -s /bin/sh -c 'makepkg -sc --noconfirm'
pacman -U --noconfirm ./pup-bin-*.pkg.tar.zst || exit 1

cd / || exit 1
mkdir -p ./gentoo
cd ./gentoo || exit 1
dir="$(pwd)"

echo 'Recursively scrape Gentoo Wiki'
delay=1
wget --content-disposition -H -k -p -r -e robots=off \
    -U 'Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0' \
    -D 'wiki.gentoo.org' -w "$delay" \
    'https://wiki.gentoo.org/wiki/Main_Page' \
    --include-directories 'wiki/*'

echo 'Page post-processing'
# Add extension
find "$dir/wiki.gentoo.org/wiki" -type f -exec mv {} {}.html \;
# Strip header and footer
find "$dir/wiki.gentoo.org/wiki" -type f -print0 | xargs -0  --no-run-if-empty -I{} sh -c "cat \"{}\" | pup 'head, div#content' --pre | sponge \"{}\""
# Use local CSS
curl -L 'https://assets.gentoo.org/tyrian/bootstrap.min.css' -o "$dir/wiki.gentoo.org/bootstrap.min.css"
curl -L 'https://assets.gentoo.org/tyrian/tyrian.min.css' -o "$dir/wiki.gentoo.org/tyrian.min.css"
find "$dir/wiki.gentoo.org/wiki" -name '*.html' -exec sed -i 's|https://assets.gentoo.org/tyrian/|/usr/share/doc/gentoo-wiki/wiki/|g; ' {} \;
# Replace links
find "$dir/wiki.gentoo.org/wiki" -name '*.html' -exec sed -i 's|https://wiki.gentoo.org/index.php?title=|/wiki/|g;' {} \;
find "$dir/wiki.gentoo.org/wiki" -name '*.html' -exec sed -i 's|index.php?title=|/usr/share/doc/gentoo-wiki/wiki/|g;' {} \;
find "$dir/wiki.gentoo.org/wiki" -name '*.html' -exec sed -i 's/href="\/wiki\/\([^"]*\)"/href="\/usr\/share\/doc\/gentoo-wiki\/wiki\/\1.html"/g; ' {} \;

mkdir -p "$dir/usr/share/doc/gentoo-wiki"
mv "$dir/wiki.gentoo.org/wiki" "$dir/usr/share/doc/gentoo-wiki"
mv "$dir/wiki.gentoo.org/bootstrap.min.css" "$dir/wiki.gentoo.org/tyrian.min.css" "$dir/usr/share/doc/gentoo-wiki"
cd "$dir" || exit 1

echo 'Compressing data'
archive="gentoo-wiki_$(date +'%Y%m%d').source.tar.xz"
tar -cJf "/release/$archive" usr/share/doc/gentoo-wiki
echo "Generated $(du -h "/release/$archive" | cut -f1) Gentoo Wiki archive"

echo 'Testing archive contents'
pagecount="$(tar -tf "/release/$archive" | grep -c '\.html$')"
if [ "$pagecount" -lt 3000 ]; then
    echo 'Error: archive page count is too low'
    exit 1
else
    echo "Archive contains ${pagecount} HTML pages"
fi

echo 'Done'
