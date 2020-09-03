#!/usr/bin/env bash

_wikiman_widget () {

	if [[ "$READLINE_LINE" =~ [^[:space:]] ]]; then
		echo "wikiman: searching for '$READLINE_LINE'..."
		wikiman $READLINE_LINE
	else
		echo "wikiman: fetching all entries..."
		wikiman
	fi

	READLINE_POINT=${#READLINE_LINE}

}

bind -x '"\C-f": _wikiman_widget'
