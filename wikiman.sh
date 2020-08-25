#! /bin/sh

wiki_dir='/usr/share/doc/arch-wiki/html/en'
workdir="$(mktemp -d -t 'wiki-XXXXXXXXXX')"

find "$wiki_dir" -type f > "$workdir/__wiki_all_entries__"
man -k . > "$workdir/__manpage_all_entries__"

if [ $# -eq 0 ]; then

    cat "$workdir/__manpage_all_entries__" | sed 's/ .*$/ [Manual]/g' >> "$workdir/__final_results__"
    cat "$workdir/__wiki_all_entries__" | xargs -I{} realpath --relative-to="$wiki_dir" {} | sed 's/.html$/ [ArchWiki]/g' >> "$workdir/__final_results__"

    sort -h -f "$workdir/__final_results__" -o "$workdir/__final_results__"

else

    for word in "$@"; do
        # rg -U -S -c "$word" "$wiki_dir" | sed 's/\(.*\)\:\(.*\)/\2\t\1/' | sort -n -r | head -n 20 > "$workdir/$word"
        rg -U -S -c "$word" "$wiki_dir" | sed 's/\(.*\)\:\(.*\)/\2\t\1/' | sort -n -r > "$workdir/$word"
        cat "$workdir/$word" >> "$workdir/__wiki_content_match__"
        grep -i "$word" "$workdir/__wiki_all_entries__" >> "$workdir/__wiki_title_match__"
        cat "$workdir/__manpage_all_entries__" | cut -d' ' -f1  | grep -e "$word" >> "$workdir/__manpage_title_match__"
        grep -e "$word" "$workdir/__manpage_all_entries__" | cut -d' ' -f1 >> "$workdir/__manpage_content_match__"
    done

    awk -F '\t' '{a[$2] += $1} END{for (i in a) print i}' "$workdir/__wiki_content_match__" | sort -n -r | sed '/^Category/d' >>  "$workdir/__wiki_content_results__"

    cat "$workdir/__manpage_title_match__" | sed 's/$/ [Manual]/g' >> "$workdir/__results__"
    cat "$workdir/__wiki_title_match__" | xargs -I{} realpath --relative-to="$wiki_dir" {} | sed 's/.html$/ [ArchWiki]/g' >> "$workdir/__results__"
    cat "$workdir/__manpage_content_match__" | sed 's/$/ [Manual]/g' >> "$workdir/__results__"
    cat "$workdir/__wiki_content_results__" | xargs -I{} realpath --relative-to="$wiki_dir" {} | sed 's/.html$/ [ArchWiki]/g' >> "$workdir/__results__"

    awk '!visited[$0]++' "$workdir/__results__" > "$workdir/__final_results__"

fi





selected="$(echo "$(zenity  --title="Results" --list --width=600 --height=800 \
                          --column="Name" $(cat "$workdir/__final_results__" | sed 's/ //g'))" \
                          | sed 's/\[/ \[/g')"




#selected="$(cat "$workdir/__final_results__" | fzf)"



echo "$selected" | grep -q ' \[ArchWiki\]$' && \
    links "$wiki_dir/$(echo $selected | sed 's/ \[.*\]$/.html/g')" ||
    man "$(echo $selected | cut -d ' ' -f1)"

