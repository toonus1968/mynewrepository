#!/bin/bash

STICK=$(df | awk '$NF ~ /\/media\/neep/ { print $NF }')
typeset -i NUM_I=0
case ${STICK} in
   /media/neep/0123-4567) DIRS="Best_of Artists Playlists" ;;
   /media/neep/9C33-6BBD) DIRS="Artists Playlists"         ;;
esac

for DIR in ${DIRS}
do
  cd ${STICK}/${DIR}
  [[ $? -ne 0 || ! -d ${STICK}/${DIR} ]] && echo "Directory ${DIR} ..." && exit

  unset NUM_I NUM_II PLAYLIST PLAYLISTS

  while read PLAYLIST
  do
    PLAYLISTS[${NUM_I}]="${PLAYLIST}" 
    ((NUM_I+=1))
  done < <(ls -1 *m3u)
  typeset -i NUM_I=0
  while [  ${NUM_I} -lt ${#PLAYLISTS[@]} ]
  do
    unset OK ERROR;typeset -i NUM_II=0
    echo -e "Verifying ${PLAYLISTS[${NUM_I}]}..."
    while read SONG
    do
      if [ -s "${SONG}" ]
      then
             OK[${NUM_II}]="${SONG}"
      else
          ERROR[${NUM_II}]="${SONG}"
      fi
      ((NUM_II+=1))
    done < <(awk -v stick=${STICK} '$1 ~ /^\\/ { gsub( "\\",  "/",$0 )
                                                 gsub( "\015", "",$0 ); print stick$0 }' "${PLAYLISTS[${NUM_I}]}")
    if [ ${#ERROR[@]} -eq 0 ]
    then
        echo -e "  [ok] : all songs (${#OK[@]} exist for: ${PLAYLISTS[${NUM_I}]}..."
    else
        echo -e "  [ok] : NOT all   (${#ERROR[@]} songs exist for: ${PLAYLISTS[${NUM_I}]}..."
        for i in "${ERROR[@]}"
        do
          echo -e "       : $i"
        done
        read dummy
    fi
    ((NUM_I+=1))
  done 
done
