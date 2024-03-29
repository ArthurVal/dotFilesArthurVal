#!/usr/bin/env bash

# set the icon and a temporary location for the screenshot to be stored
# icon="$HOME/images/lock-icon-light.png"
tmpbg='/tmp/lock_screen.png'


if [ ! -f "$tmpbg" ]; then
    # take a screenshot
    scrot  "$tmpbg"

    # blur the screenshot by resizing and scaling back up
    convert "$tmpbg" -filter Gaussian -thumbnail 20% -sample 500% "$tmpbg"
fi

# overlay the icon onto the screenshot
# convert "$tmpbg" "$icon" -gravity center -composite "$tmpbg"

# lock the screen with the blurred screenshot
i3lock -i "$tmpbg"
