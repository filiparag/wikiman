#!/bin/sh

# Targeted for Arch Linux

mkdir -p ./gentoo

cd ./gentoo

dir="$(pwd)"

wget --content-disposition -H -k -p -r -e robots=off \
    -U 'Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0' \
    -D 'wiki.gentoo.org' \
    'https://wiki.gentoo.org/wiki/Main_Page' \
    --include-directories 'wiki/*'

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