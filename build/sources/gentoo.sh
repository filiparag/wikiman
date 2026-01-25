#!/usr/bin/env bash

export XZ_OPT=-e9T0

echo 'Installing tools'
pacman -Sy --noconfirm curl wget git base-devel moreutils parallel

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

mkdir -p "$dir/gentoo-wiki"
cd "$dir/gentoo-wiki" || exit 1

echo 'Recursively scrape Gentoo Wiki'
delay=1
wget --content-disposition -H -k -p -r -e robots=off -np \
    -U 'Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0' \
    -D 'wiki.gentoo.org' -w "$delay" \
    -nH --cut-dirs=0 \
    'https://wiki.gentoo.org/wiki/Main_Page' \
    --include-directories 'wiki/*'

echo 'Page post-processing'
# Add extension
find "$dir/gentoo-wiki/wiki" -type f -not -name "*.html" -not -name "*.css" -not -name "*.js" -exec mv {} {}.html \;
# Strip header and footer
find "$dir/gentoo-wiki/wiki" -name "*.html" | parallel --will-cite -N 64 \
    'sh -c "for f in \"\$@\"; do pup \"head, div#content\" --pre < \"\$f\" | sponge \"\$f\"; done" _ {}'
# Fetch remote assets
curl -L 'https://assets.gentoo.org/tyrian/bootstrap.min.css' -o "$dir/gentoo-wiki/bootstrap.min.css"
curl -L 'https://assets.gentoo.org/tyrian/tyrian.min.css' -o "$dir/gentoo-wiki/tyrian.min.css"
curl -L 'https://assets.gentoo.org/tyrian/Bitter-Regular.woff' -o "$dir/gentoo-wiki/Bitter-Regular.woff"
curl -L 'https://assets.gentoo.org/tyrian/OpenSans-Regular.woff' -o "$dir/gentoo-wiki/OpenSans-Regular.woff"
curl -L 'https://assets.gentoo.org/tyrian/fontawesome-webfont.woff2' -o "$dir/gentoo-wiki/fontawesome-webfont.woff2"
curl -L 'https://www.gentoo.org/favicon.ico' -o "$dir/gentoo-wiki/favicon.ico"

# Use local assets
process_links() {
    file="$1"
    base_dir="$2"

    rel_to_root=$(realpath --relative-to="$(dirname "$file")" "$base_dir")
    [ "$rel_to_root" = "." ] && rel_to_root="."

    sed -i "s|https://assets.gentoo.org/tyrian/|$rel_to_root/|g" "$file"
    sed -i "s|href=\"/wiki/\([^\"]*\)\"|href=\"$rel_to_root/\1.html\"|g" "$file"

    sed -i "s|https://wiki.gentoo.org/index.php?title=|$rel_to_root/|g" "$file"
    sed -i "s|index.php?title=|$rel_to_root/|g" "$file"

    sed -i "s|https://www.gentoo.org/favicon.ico|$rel_to_root/favicon.ico|g" "$file"
}
export -f process_links
find "$dir/gentoo-wiki/wiki" -name "*.html" | parallel --will-cite \
    process_links {} "$dir/gentoo-wiki"

cd "$dir" || exit 1

echo 'Compressing data'
archive="gentoo-wiki_$(date +'%Y%m%d').source.tar.xz"
tar -cJf "/release/$archive" gentoo-wiki
echo "Generated $(du -h "/release/$archive" | cut -f1) Gentoo Wiki archive"

echo 'Testing archive contents'
pagecount="$(tar -tf "/release/$archive" | grep -c '\.html$')"
if [ "$pagecount" -lt 2500 ]; then
    echo 'Error: archive page count is too low'
    exit 1
else
    echo "Archive contains ${pagecount} HTML pages"
fi

echo 'Done'
