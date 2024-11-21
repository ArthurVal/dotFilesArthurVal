#! /bin/sh

# Take a screenshot of the desktop and apply a gaussian blur to create
# an image to use for the lock screen.

DIR=/tmp
NAME=sway_lock_img

TMP_SCREENSHOT=${DIR}/${NAME}_tmp.png
BKG_IMG=${DIR}/${NAME}.png

grim ${TMP_SCREENSHOT}
ffmpeg -i ${TMP_SCREENSHOT} -filter_complex "gblur=sigma=50" ${BKG_IMG} -y
rm ${TMP_SCREENSHOT}

swaylock -f -i "${BKG_IMG}"
