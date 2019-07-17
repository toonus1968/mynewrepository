#!/bin/bash

if [ $# -ne 0 ]
then
   if  [ $# -eq 1 ]
   then
       case $(echo $1 | awk '{ print tolower($1) }') in
        --no_verify) NO_VERIFY=true                                                                                   ;;
                  *) echo -e "\n\n\t\t`tput rev`**ERROR**`tput sgr0` usage: $(basename $0) [--no_verify]\n\n";exit 99 ;;
       esac
   else
       echo                -e "\n\n\t\t`tput rev`**ERROR**`tput sgr0` usage: $(basename $0) [--no_verify]\n\n";exit 99
   fi
fi


#######################################################################################
# Declare the required variables.                                                     #
#######################################################################################
InitSettings(){
 EXCLUDE=/home/neep/music_scripts/exclude.dirs
FLAGFILE=/mnt/neep-nas/iTunes/lastrun_PHONE
  SOURCE=/mnt/neep-nas/iTunes/Music/Music
PLAYLIST_SOURCE=/mnt/neep-nas/iTunes/playlist
#
# Ensure the music on the NAS is accessable...otherwise don't do anything:
#
if [ $(mount -t cifs 2>/dev/null | grep -wc neep-nas) -eq 0 ]
then
    mount -t cifs -o vers=1.0 //192.168.1.110/service /mnt/neep-nas -o user=admin -o password=${PASSWORD}
    if [  $(mount -t cifs 2>/dev/null | grep -wc neep-nas) -eq 0 ]
    then
        echo -e "\t /mnt/neep-nas niet aanwezig...exiting! \t\t"; exit 99
    fi
fi
if [ -d             /media/neep/9C33-6BBD/Music ]
then
       MUSIC_TARGET=/media/neep/9C33-6BBD/Music
             TARGET=/media/neep/9C33-6BBD/Artists
    PLAYLIST_TARGET=/media/neep/9C33-6BBD/Playlists
else
             TARGET=/home/neep/music_scripts/m3u
    PLAYLIST_TARGET=/home/neep/music_scripts/Playlists
fi
mkdir -p ${TARGET} ${PLAYLIST_TARGET} 2>/dev/null
}

#######################################################################################
# Copy all music on the NAS newer than ${FLAGFILE to the SD-card.                     #
#######################################################################################
Copy2SDCard(){
if [ -d  /media/neep/9C33-6BBD/Music ]
then
    
    cd /mnt/neep-nas/iTunes/playlist_phn 
    find . -type f                    | cpio --no-preserve-owner -padmu ${PLAYLIST_TARGET} 2>/dev/null
    cd "${SOURCE}"
    find . -type f -newer ${FLAGFILE} | cpio --no-preserve-owner -padmu ${MUSIC_TARGET}    2>/dev/null
    touch ${FLAGFILE}
fi
}

#######################################################################################
# Verify the playlists which are on the USB-stick.                                    #
#######################################################################################
VerifyPlaylists(){
for DIR in ${TARGET} ${PLAYLIST_TARGET} 
do
  unset NUM_I NUM_II PLAYLIST PLAYLISTS
  cd ${DIR};[[ $? -ne 0 || ! -d ${STICK}/${DIR} ]] && echo "Directory ${DIR} doesn't exist..." && break

  while read PLAYLIST
  do
    PLAYLISTS[${NUM_I}]="${PLAYLIST}"
    ((NUM_I+=1))
  done < <(ls -1 *m3u)
  typeset -i NUM_I=0
  while [  ${NUM_I} -lt ${#PLAYLISTS[@]} ]
  do
    unset OKS ERRORS;typeset -i NUM_II=0
    echo -e "Verifying ${PLAYLISTS[${NUM_I}]}..."
    while read SONG
    do
      if [ -s "${SONG}" ]
      then
             OKS[${NUM_II}]="${SONG}"
      else
          ERRORS[${NUM_II}]="${SONG}"
      fi
      ((NUM_II+=1))
    done < <(awk -v dir=$(dirname ${DIR}) '$1 ~ /^\\/ { gsub( "\\",  "/",$0 )
                                                        gsub( "\015", "",$0 ); print dir$0 }' "${PLAYLISTS[${NUM_I}]}")
    if [ ${#ERRORS[@]} -eq 0 ]
    then
        echo -e "  [ok] : all songs (${#OKS[@]}) exist for: ${DIR}/${PLAYLISTS[${NUM_I}]}..."
    else
        echo -e "  [ok] : NOT all   (${#ERRORS[@]}) songs exist for: ${DIR}/${PLAYLISTS[${NUM_I}]}..."
        for ERROR in "${ERRORS[@]}"
        do
          echo -e "       : ${ERROR}"
        done
        read dummy
    fi
    ((NUM_I+=1))
  done
done
}

################################## Main Script ########################################
#-------------------------------------------------------------------------------------#
#                                                                                     #
InitSettings
Copy2SDCard
[[ "${NO_VERIFY:=false}" != true ]] && VerifyPlaylists

echo " still to do... 200Latest and Best of The Best..." 
#                                                                                     #
#-------------------------------------------------------------------------------------#
################################## Main Script ########################################
