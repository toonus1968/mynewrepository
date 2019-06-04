#!/bin/bash

if [ $# -ne 0 ]
then
   if  [ $# -eq 1 ]
   then
       case $(echo $1 | awk '{ print tolower($1) }') in
        --allyes) DEFAULT=y ;;
         --allno) DEFAULT=n ;;
               *) echo -e "\n\n\t\t`tput rev`**ERROR**`tput sgr0` usage: $(basename $0) [--allyes|--allno]\n\n";exit 99
                  ;;
       esac
   else
       echo -e "\n\n\t\t`tput rev`**ERROR**`tput sgr0` usage: $(basename $0) [--allyes|--allno]\n\n";exit 99
   fi
else
    DEFAULT=n 
fi

#######################################################################################
# Declare the required variables.                                                     #
#######################################################################################
InitSettings(){  
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
     ON_NAS=/mnt/neep-nas/iTunes
ITUNES_FILE="${ON_NAS}/iTunes Music Library.xml"
#
# Create a "3-dimensional" array containing the Playlist names and track-numers:
#
if [ -s "${ITUNES_FILE}" ]
then
    awk '{ gsub(               "\t",             "", $0 )
           gsub(             "\015",             "", $0 )
           gsub(              "#38;",            "", $0 )
           gsub(              "%20",            " ", $0 )
           gsub(              "%23",            "#", $0 )
           gsub(        "</string>",             "", $0 )
           gsub(       "</integer>",             "", $0 )
           gsub( "file://localhost",             "", $0 )
           gsub(                "/",           "\\", $0 )
           gsub(              "%5B",            "[", $0 )
           gsub(              "%5D",            "]", $0 )
           gsub(        "%E2%80%A2", "\342\200\242", $0 ) 
           gsub(           "%C3%B8",     "\303\270", $0 )
           gsub(           "%C3%A9",     "\303\251", $0 )
           gsub(           "%C3%AA",     "\303\252", $0 )
           gsub(           "%C3%B3",     "\303\263", $0 )
           gsub(           "%C2%BA",     "\303\272", $0 )
           gsub(           "%C3%AD",     "\303\255", $0 )
           { if ( $1 ~ /^<key>[0-9]/                      ) print $0 }
           { if ( $1 ~ /^<key>Name<\\key><string>/        ) print $0 }
           { if ( $1 ~ /^<key>Artist<\\key><string>/      ) print $0 }
           { if ( $0  ~ /<key>Total Time<\\key><integer>/ ) print $0 }
           { if ( $1 ~ /^<key>Location<\\key><string>/    ) print $0 }
           { if ( $0 ~ /^<key>Track ID<\\key><integer>/   ) print $0 }
         }' "${ITUNES_FILE}" > /tmp/ITUNES_FILE.$$

    START=$(awk '$1 ~ /^<key>Name<\\key><string>Artists$/ { print NR-1 }' /tmp/ITUNES_FILE.$$)
    eval  $(awk 'BEGIN{ i=0 }
                 NR>'${START}' { { if ( $1 ~ /^<key>Name<\\key><string>/                 )
                                      { gsub( "<key>Name<\\\key><string>",        "", $0 )
                                        { for (k=1; k<=NF; k++) $k=toupper(substr($k,1,1))tolower(substr($k,2)) }
                                        gsub(                    "4Hero", "fourhero", $0 )
                                        gsub(            "Best Of\.\.\.", "XXXXXXXX", $0 )
                                        gsub(                        "-",     "XooX", $0 )
                                        gsub(                        " ",        "_", $0 )
                                        gsub(                     "\047",         "", $0 )
                                        gsub(                       "_$",         "", $0 )
                                        playlist=$0
                                        print "PLAYLIST["i"]="playlist
                                        i+=1
                                        j=0
                                      } 
                                 }
                                 { if ( $0  ~ /<key>Track ID<\\key><integer>/          )
                                      { gsub( "<key>Track ID<\\\key><integer>", "", $0 )
                                        j++
                                        print playlist"["j"]="$0
                                      }
                                 }
                               }' /tmp/ITUNES_FILE.$$)
else
    echo -e "\t${ITUNES_FILE} does NOT exists or it is empty, exiting...\n\n";exit 99
fi
#
# Ask to confirm/decline to use the Playlist:
#
typeset -i NUM=0
for SELECT in ${PLAYLIST[@]}
do
  eval $(echo ${SELECT} | awk '{ gsub(         "_",     " ", $0 )
                                 gsub(      "XooX",     "-", $0 )
                                 gsub(  "fourhero", "4Hero", $0 )
                                 print "PLAYLIST_NAME=\""$0"\"" }')
  if [[ "${PLAYLIST_NAME}" !=  "Artists" && "${PLAYLIST_NAME}" != "Teep" && "${PLAYLIST_NAME}" != "Dekleine" && "${PLAYLIST_NAME}" != "Thuis" && "${PLAYLIST_NAME}" != "XXXXXXXX" ]]
  then
      unset ANSWER
      while [[ "${ANSWER}" != "y" && "${ANSWER}" != "n" ]]
      do
        tput civis
        echo -e "\tDo you want to export from the iTunes Library:\t ${PLAYLIST_NAME}\n\t\t\t [yY|nN]: => `tput rev`${DEFAULT}`tput sgr0`\b\c"
        read ANSWER;ANSWER=$(echo ${ANSWER:=${DEFAULT}} | awk '{ print tolower($1) }')
        tput cvvis
      done
      case ${ANSWER} in
           y) echo -e "\t\tConfirmed to use:\t ${PLAYLIST_NAME}\n"
              ;;
           n) echo -e   "\tDeclined to use :\t ${PLAYLIST_NAME}"
              PLAYLIST[${NUM}]=""
              ;;
      esac
  else
      PLAYLIST[${NUM}]=""
  fi
  ((NUM+=1))
done
}

#######################################################################################
# Export the Playlist from iTunes in m3u-format.                                      #
#######################################################################################
ExportPlaylastFromiTunes(){
echo -e "#EXTM3U\015" >/tmp/temp.$$
for LINE in ${USE_LIST}
do
  START=$(awk '$1 ~ /^<key>'${LINE}'<\\key>/ { print NR;exit }' /tmp/ITUNES_FILE.$$)
  awk 'NR>'${START}' && NR<('${START}'+8) { sub( "the national", "The National", $0 )
                                            { if ( $1 ~ /^<key>Name<\\key><string>/        && length(name)     == 0 ) { gsub( "<key>Name<\\\key><string>"       , "", $0 );name=$0      } }
                                            { if ( $1 ~ /^<key>Artist<\\key><string>/      && length(artist)   == 0 ) { gsub( "<key>Artist<\\\key><string>"     , "", $0 );artist=$0    } }
                                            { if ( $0  ~ /<key>Total Time<\\key><integer>/ && length(time)     == 0 ) { gsub( "<key>Total Time<\\\key><integer>", "", $0 );time=$0/1000 } }
                                            { if ( $1 ~ /^<key>Location<\\key><string>/    && length(location) == 0 ) { gsub( "<key>Location<\\\key><string>"   , "", $0 );location=$0  } }
                                            }
                                            END{ { if ( location ~ /^\\C/ ) location=substr(location,2) }
                                                 printf ( "%8s%3.0f%s %s %s%s%s%s\n","#EXTINF:",time,","name,"-",artist,"\015\n",location,"\015" ) >>"'/tmp/temp.$$'"
                                                 print  "\t\tProcessing: "name" - "artist }' /tmp/ITUNES_FILE.$$
done
eval $(echo ${PLAYLIST_NAME} | awk '{ gsub(         "_",     " ", $0 )
                                      gsub(      "XooX",     "-", $0 )
                                      gsub(  "fourhero", "4Hero", $0 )
                                      print "PLAYLIST_NAME=\""$0"\"" }')
if [ $(grep -c % /tmp/temp.$$ 2>/dev/null) -ne 0 ]
then
    echo -e "\n\n\t\t: ${PLAYLIST_NAME} contains extra/strange characters, please examine...\n\n"
    read dummy
fi
mv -f /tmp/temp.$$ ${ON_NAS}/playlist/"${PLAYLIST_NAME}".m3u
}

################################## Main Script ########################################
#-------------------------------------------------------------------------------------#
#                                                                                     #
InitSettings
for PLAYLIST_NAME in ${PLAYLIST[@]}
do
  echo -e "\tExporting from the iTunes Library: ${PLAYLIST_NAME}"
  eval USE_LIST=\$"{${PLAYLIST_NAME}[@]}"
  ExportPlaylastFromiTunes 
done
rm -f /tmp/ITUNES_FILE.$$
#                                                                                     #
#-------------------------------------------------------------------------------------#
################################## Main Script ########################################
