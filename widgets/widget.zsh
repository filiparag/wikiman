#!/usr/bin/env zsh

_wikiman_widget() {
  
	if [[ "$LBUFFER" =~ [^[:space:]] ]]; then
		echo "wikiman: searching for '$LBUFFER'..."
		wikiman $LBUFFER
	else
		echo "wikiman: fetching all entries..."
		wikiman
	fi

  zle redisplay

}

zle -N _wikiman_widget

bindkey '^f' _wikiman_widget
