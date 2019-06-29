#!/bin/bash

#######################################################################################
# Declare the required variables.                                                     #
#######################################################################################
InitSettings(){
 EXCLUDE=/home/neep/music_scripts/exclude.dirs
FLAGFILE=/mnt/neep-nas/iTunes/lastrun_AUDI
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
if [ -d             /media/neep/0123-4567/Music ]
then
       MUSIC_TARGET=/media/neep/0123-4567/Music
       PHONE_TARGET=/media/neep/9C33-6BBD/Music
             TARGET=/media/neep/0123-4567/Artists
    PLAYLIST_TARGET=/media/neep/0123-4567/Playlists
     BEST_OF_TARGET=/media/neep/0123-4567/Best_Of
     PLAYLIST_PHONE=/media/neep/9C33-6BBD/Playlists
else
             TARGET=/home/neep/music_scripts/m3u
    PLAYLIST_TARGET=/home/neep/music_scripts/Playlists
fi
mkdir -p ${BEST_OF_TARGET} ${TARGET} ${PLAYLIST_TARGET} 2>/dev/null
}

#######################################################################################
# Convert iTunes playlists.                                                           #
#######################################################################################
ConvertiTunesPlaylists(){
# 
# Have all playlist such as they were exported from iTunes and stored on the NAS converted:
#
eval $(find ${PLAYLIST_SOURCE}/ -type f 2>/dev/null | grep -w m3u$  | awk -F/ '{ print "PLAYLISTS["NR"]=\""$NF"\"" }')
typeset -i NR=1
while [ ${NR} -le ${#PLAYLISTS[@]} ]
do
  echo -e "\t Processing iTunes playlist:\t ${PLAYLISTS[$NR]}..."
  awk '{ { if ( $1 ~ /192.168/ ) 
             print substr($0,37) 
           else
             { { if ( tolower($1) ~ /neep-nas/ ) 
                    print substr($0,32) 
                  else
                    { { if ( tolower($1) ~ /'${PASSWORD}'/ )  
                           print substr($0,43) 
                        else
                           print $0
                      }
                    }
               }
             }
          }
       }'              ${PLAYLIST_SOURCE}/"${PLAYLISTS[$NR]}" | uniq > ${PLAYLIST_TARGET}/"${PLAYLISTS[$NR]}".$$
  if [[ $? -eq 0 && -s ${PLAYLIST_TARGET}/"${PLAYLISTS[$NR]}".$$ ]]
  then
      if [ $(echo ${PLAYLISTS[$NR]} | grep -wc ^Best) -eq 0 ]
      then
          TO_DIR=${PLAYLIST_TARGET}
      else
          TO_DIR=${BEST_OF_TARGET}
      fi
      mv -f            ${PLAYLIST_TARGET}/"${PLAYLISTS[$NR]}".$$ ${TO_DIR}/"${PLAYLISTS[$NR]}"
  fi
  awk '{ { if ( $0 ~ /^#/ )
              print $0 
           else
              { gsub( "\\", "/", $0 )
                { if ( tolower($1) ~ /^\/music/ )
                     print "/mnt/neep-nas/iTunes/Music"$0
                  else
                     print $0
                }
              }
         }
       }' ${TO_DIR}/"${PLAYLISTS[$NR]}" > ~neep/music_scripts/Playlists_LNX/"${PLAYLISTS[$NR]}"
       cp -fp                             ~neep/music_scripts/Playlists_LNX/"${PLAYLISTS[$NR]}" /mnt/neep-nas/iTunes/playlist_lnx
  awk '{ { if ( $0 ~ /^#/ )
              print $0
           else
              { gsub( "\\", "/", $0 )
                { if ( tolower($1) ~ /^\/music/ )
                     print "smb://neepies:${PASSWORD}@192.168.1.110/service/iTunes/Music"$0
                  else
                     print $0
                }
              }
         }
       }' ${TO_DIR}/"${PLAYLISTS[$NR]}" > ~neep/music_scripts/Playlists_AND/"${PLAYLISTS[$NR]}"
       cp -fp                             ~neep/music_scripts/Playlists_AND/"${PLAYLISTS[$NR]}" /mnt/neep-nas/iTunes/playlist_and
  awk '{ { if ( $0 ~ /^#/ )
              print $0
           else
              { gsub(   "\\", "/", $0 )
                 sub( "\015",  "", $0 )
                 { if ( tolower($1) ~ /^\/music/ )
                     print "/storage/93c33-6BBD/Music"$0
                  else
                     print $0
                }
              }
         }
       }' ${TO_DIR}/"${PLAYLISTS[$NR]}" > ~neep/music_scripts/Playlists_PHN/000_"${PLAYLISTS[$NR]}"
       cp -fp                             ~neep/music_scripts/Playlists_PHN/000_"${PLAYLISTS[$NR]}" /mnt/neep-nas/iTunes/playlist_phn/000_"${PLAYLISTS[$NR]}"
       # 
       # hier moet het komen...
       #
  ((NR+=1))
done
}

#######################################################################################
# Create Artists playlists.                                                           #
#######################################################################################
CreateArtistPlaylists(){
#
# Have for each artist such as found on the NAS a customized playlist created:
#
while read ARTIST
do
  echo -e "\t Processing customized playlist:\t ${ARTIST}..."
  ( echo -e "#EXTM3U\015"
    while read FILE
    do
      avconv -i "${FILE}" 2>&1 | awk -F: 'BEGIN{ printf "#EXTINF:" }
                                          $1 ~ / Duration$/                     { duration=($2*3600)+($3*60)+substr($4,1,2) }
                                          $1 ~ / album /                        {    album=$2                               }
                                          $1 ~ / artist /                       {   artist=$2                               }
                                          $1 ~ / title / && length(title) == 0  {    title=$2                               }
                                          END{ print duration","artist" -"title" :"album"\015" }' 
      echo "${FILE}" | awk -F/ '{ for (i=6; i<=NF; i++)  printf "\\"$i }END{ print "\015" }'
    done< <(find "${SOURCE}"/"${ARTIST}" -type f 2>/dev/null | grep -we mp3$ -we m4a$ 2>/dev/null | sort -n)
  ) > ${TARGET}/"${ARTIST}".m3u
  awk '{ { if ( $0 ~ /^#/ )
             print $0
          else
             { gsub( "\\", "/", $0 )
               { if ( tolower($1) ~ /^\/music/ )
                    print "/mnt/neep-nas/iTunes/Music"$0
                 else
                    print $0
               }
             }
        }
      }' ${TARGET}/"${ARTIST}".m3u  > /mnt/neep-nas/iTunes/playlist_lnx/Artists/"${ARTIST}".m3u
  awk '{ { if ( $0 ~ /^#/ )
              print $0
           else
              { gsub( "\\", "/", $0 )
                { if ( tolower($1) ~ /^\/music/ )
                     print "smb://neepies:${PASSWORD}@192.168.1.110/service/iTunes/Music"$0
                  else
                     print $0
                }
              }
         }
       }' ${TARGET}/"${ARTIST}".m3u  > /mnt/neep-nas/iTunes/playlist_and/Artists/"${ARTIST}".m3u
done< <(find "${SOURCE}"/ -type f -newer ${FLAGFILE} 2>/dev/null | grep -we mp3$ -we m4a$ 2>/dev/null | awk -F/ '{ print $7 }' | sort | uniq | fgrep -vf ${EXCLUDE})
}


#######################################################################################
# Create directory with the last/latest 200 songs and the Latest200-Playlist.         #
#######################################################################################
CreateLatest200Directory(){ 
#
# Create a directory and playlist which contains the latest 200 added songs to the library:
#
typeset -i PROCESSED=0
mkdir -p ${MUSIC_TARGET}/200Latest 1>/dev/null 2>&1
echo -e "\t Processing Latest 200-Songs   :"
echo -e "#EXTM3U\015" >${PLAYLIST_TARGET}/Latest-200.m3u
while read FIND_FROM
do
  while read FILE
  do
    ((PROCESSED+=1))
    if [ ${PROCESSED} -gt 200 ]
    then
        break
    fi
    case "${FILE}" in
          *.mp3) EXT=mp3 ;;
          *.m4a) EXT=m4a ;;
    esac
    COPY_FILE=$(avconv -i "${FILE}" 2>&1 | awk -F: '$1 ~ / Duration$/                     { duration=($2*3600)+($3*60)+substr($4,1,2) }
                                                    $1 ~ / album /                        {    album=$2                               }
                                                    $1 ~ / artist /                       {   artist=substr($2,2)                     }
                                                    $1 ~ / title / && length(title) == 0  {    title=$2                               }
                                                    END{ print "#EXTINF:"duration","artist" -"title" :"album"\015" >>"'${PLAYLIST_TARGET}'/Latest-200.m3u"
                                                         print artist" -"album" -"title".'${EXT}'"     
                                                       }')
    echo       -e "\Music\\200Latest\\${COPY_FILE}\015" >>${PLAYLIST_TARGET}/Latest-200.m3u
    echo -e "\t                               : $(echo ${PROCESSED} | awk '{ printf "%3.3d\n",$1 }') \c"
    if [ -s "${MUSIC_TARGET}/200Latest/${COPY_FILE}" ]
    then
        echo "skip: ${COPY_FILE}"
    else
        echo "copy: ${COPY_FILE}"
        cp -fp "${FILE}" "${MUSIC_TARGET}/200Latest/${COPY_FILE}" 1>/dev/null 2>&1
    fi
    
  done< <(find "${FIND_FROM}"/ -type f -ctime -450 \( -name "*.mp3" -o -name "*.m4a" \) 2>/dev/null | fgrep -vf ${EXCLUDE} |\
                 awk '{ ("stat -c %X ""\""  $0 "\"" ) | getline date
                        print date":"$0
                     }' | sort -nr | awk -F: '{ print $2 }')
done< <(find ${SOURCE}/ -type d -newer ${FLAGFILE} 2>/dev/null | grep -vw Music/$ | awk '{ ("stat -c %X ""\""  $0 "\"" ) | getline date
                                                                                           print date":"$0
                                                                                         }' | awk -F/ 'NF>7 { print $0 }' | sort -nr | awk -F: 'NR<35 { print $2 }')

awk '{ { if ( $0 ~ /^#/ )
           print $0
        else
           { gsub( "\\", "/", $0 )
             { if ( tolower($1) ~ /^\/music/ )
                  print "/mnt/neep-nas/iTunes/Music"$0
               else
                  print $0
             }
           }
       }
     }' ${PLAYLIST_TARGET}/Latest-200.m3u > /mnt/neep-nas/iTunes/playlist_lnx/Latest-200.m3u
awk '{ { if ( $0 ~ /^#/ )
            print $0
         else
            { gsub( "\\", "/", $0 )
              { if ( tolower($1) ~ /^\/music/ )
                   print "smb://neepies:${PASSWORD}@192.168.1.110/service/iTunes/Music"$0
                else
                   print $0
              }
            }
       }
     }' ${PLAYLIST_TARGET}/Latest-200.m3u > /mnt/neep-nas/iTunes/playlist_and/Latest-200.m3u
# 
# Now make sure to remain just 200-songs:
#
ls -1t ${MUSIC_TARGET}/200Latest/* 2>/dev/null | grep -we mp3$ -we m4a$ | awk 'NR>201 { system("rm -f ""\""  $0 "\"" ) } '
}

#######################################################################################
# Copy all music on the NAS newer than ${FLAGFILE} to the SD-cards                    #
#######################################################################################
Copy2SDCard(){
if [ -d  /media/neep/0123-4567/Music ]
then
    cd "${SOURCE}"
    find . -type f -newer ${FLAGFILE} | cpio --no-preserve-owner -padmuv ${MUSIC_TARGET} 2>/dev/null
    touch                 ${FLAGFILE}
    if [ -d  /media/neep/9C33-6BBD/Music ]
    then
        #
        # Sync the contents of the 2 sims:
        #
        cd  ${MUSIC_TARGET}
        find . -type f -newer ${FLAGFILE} | cpio --no-preserve-owner -padmuv ${PHONE_TARGET} 2>/dev/null
    fi
fi
}

################################## Main Script ########################################
#-------------------------------------------------------------------------------------#
#                                                                                     #
InitSettings
ConvertiTunesPlaylists
CreateArtistPlaylists
CreateLatest200Directory
Copy2SDCard
#                                                                                     #
#-------------------------------------------------------------------------------------#
################################## Main Script ########################################
