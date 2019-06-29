#!/bin/bash

STICK=$(df | awk '$NF ~ /\/media\/neep/ { print $NF }')
typeset -i NUM_I=0

~neep/music_scripts/mount_nas 1>/dev/null 2>&1

cd /mnt/neep-nas/iTunes/Music/Music
[[ $? -ne 0 || ! -d /mnt/neep-nas/iTunes/Music/Music ]] && echo "NAS is not mounted..." && exit

while read SONG
do
  if [[ ! -s "${STICK}/Music/${SONG}" ]] 
  then
      echo      "${SONG}"
      mkdir -p           "${STICK}/Music/$(dirname "${SONG}")"
      cp    -f "${SONG}" "${STICK}/Music/$(dirname "${SONG}")" 
  fi
done < <(find . -type f  \( -name "*.mp3" -o -name "*.m4a" \) )
