#!/usr/bin/env bash

tmpbg='/tmp/lock_screen.png'


if [ ! -f "${tmpbg}" ]; then
    grim  "${tmpbg}"
    convert "${tmpbg}" -filter Gaussian -thumbnail 20% -sample 500% "${tmpbg}"
fi

swaylock -f -i "${tmpbg}"
