#!/usr/bin/env fish

function _wikiman_widget -d "Run Wikiman in list mode"

	set user_input (commandline -b)

	if string match -r '\w' $user_input
		echo "wikiman: searching for '$user_input'..."
		wikiman $user_input
	else
		echo "wikiman: fetching all entries..."
		wikiman
	end

	commandline -f repaint

end

bind \cf _wikiman_widget

if bind -M insert > /dev/null 2>&1
  bind -M insert \cf _wikiman_widget
end
