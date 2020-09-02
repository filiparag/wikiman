#!/bin/bash

mkdir -p ./arch

cd ./arch

dir="$(pwd)"

yay -S python-simplemediawiki --noconfirm

pip install --user cssselect

git clone https://github.com/lahwaacz/arch-wiki-docs

python ./arch-wiki-docs/arch-wiki-docs.py --output-directory "$dir/doc"

mkdir -p "$dir/usr/share/doc/arch-wiki"
mv "$dir/doc" "$dir/usr/share/doc/arch-wiki/html"

tar -cjf "../arch-wiki_$(date +'%Y%m%d').tar.xz" "usr/share/doc/arch-wiki/html"

cd ..

rm -rf "$dir"