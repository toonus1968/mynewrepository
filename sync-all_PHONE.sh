#!/bin/bash

#######################################################################################
# Declare the required variables.                                                     #
#######################################################################################
InitSettings(){
 EXCLUDE=/home/neep/music_scripts/exclude.dirs
FLAGFILE=/home/neep/music_scripts/lastrun_PHONE
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

################################## Main Script ########################################
#-------------------------------------------------------------------------------------#
#                                                                                     #
InitSettings
Copy2SDCard
#                                                                                     #
#-------------------------------------------------------------------------------------#
################################## Main Script ########################################
