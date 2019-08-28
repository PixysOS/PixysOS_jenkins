#!/usr/bin/env bash
#
# Copyright (C) 2019 PixysOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# PixysOS ROM building script.


function build_json() {
   timestamp=$(cat system/build.prop | grep ro.pixys.build.date | cut -d'=' -f2)
   name=$(stat -c %n "${ZIP}" | sed 's/.*\///')
   filehash=$(md5sum "${ZIP}" | cut -d " " -f 1)
   size=$(cat "${ZIP}" | wc -c)
   MAIN_URL="https://downloads.sourceforge.net/project/pixys-os/pie/${DEVICE}/${ZIP}"
   msg=$(mktemp)
   {
      echo -e "{"
      echo -e "  \x22response\x22: ["
      echo -e "    {"
      echo -e "      \x22datetime\x22: ${timestamp},"
      echo -e "      \x22filename\x22: \x22${name}\x22,"
      echo -e "      \x22id\x22: \x22${filehash}\x22,"
      echo -e "      \x22size\x22: ${size},"
      echo -e "      \x22romtype\x22: \x22official\x22,"
      echo -e "      \x22url\x22: \x22${MAIN_URL}\x22,"
      echo -e "      \x22version\x22: \x22v2.4\x22"
      echo -e "    }"
      echo -e "  ]"
      echo -e "}"
   } > "${msg}"
   
   BJSON=$(cat "${msg}")
   echo "${BJSON}" > "${JSON}"
}

# function to store logs
function TGlogs() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001322414571&parse_mode=HTML" > /dev/null
}

# function to send messages on maintainers group
function sendTG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001239809576&parse_mode=HTML" > /dev/null
}

# Additonal function to used in future versions
function TG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=${chat_id}&parse_mode=Markdown" > /dev/null
}

#function to connect to ssh 
function sshc() {
  export spass
  sshpass -p "${spass}" ssh -p 5615 -o StrictHostKeyChecking=no root@pixys.shreejoydash.me "${1}"
}

#function to make scp upload
function scpc() {
  export spass
  sshpass -p "${spass}" scp -P 5615 -o StrictHostKeyChecking=no "${1}" root@pixys.shreejoydash.me:/home/ftp/uploads/.test/"${DEVICE}"
}

# Function to upload to del.dog
function deldog() {
    RESULT=$(curl -sf --data-binary @"${1:--}" https://del.dog/documents) || {
        echo "ERROR: failed to post document" >&2
        exit 1
    }
    KEY=$(jq -r .key <<< "${RESULT}")
    DEL_NORM="https://del.dog/${KEY}"
    DEL_RAW="https://del.dog/raw/${KEY}"
}

function upload_ftp() {
   msg=$(mktemp)
   if [ "$status" == "passed" ]
   then 
      if [ "$upload" == "true" ]
      then
         echo "http://downloads.pixysos.com/.test/${DEVICE}/${ZIP}" > "${msg}"
         deldog "${msg}"
	 DL_LINK="${DEL_NORM}"
         echo -e "Uploading test artifact ${ZIP}"
         sshc "rm -rf /home/ftp/uploads/.test/${DEVICE}"
         sshc "mkdir /home/ftp/uploads/.test/${DEVICE}"
         scpc "${ZIP}"
         scpc "${JSON}"
	 {
	     echo "🏷 <b>Build Completed</b>"
   	     echo 
   	     echo "<b>Device</b> :- #${DEVICE}"
   	     echo "<b>Build URL</b> :- <a href=\"${BUILD_URL}console\">LINK</a>"
   	     echo "<b>Build time</b> :- $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
   	     echo
   	     echo "<b>Status</b> :- Passed ✅"
   	     echo "⬇️ <a href=\"${DL_LINK}\">Download</a>"
	  } > "${msg}"
       elif [ "$upload" == "false" ]
       then
 	 {
	     echo "🏷 <b>Build Completed</b>"
   	     echo 
   	     echo "<b>Device</b> :- #${DEVICE}"
   	     echo "<b>Build URL</b> :- <a href=\"${BUILD_URL}console\">LINK</a>"
   	     echo "<b>Build time</b> :- $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
   	     echo
   	     echo "<b>Status</b> :- Passed ✅"
	  } > "${msg}"
       fi
    elif [ "$status" == "failed" ]
    then
 	  {
	     echo "🏷 <b>Build Completed</b>"
   	     echo 
   	     echo "<b>Device</b> :- #${DEVICE}"
   	     echo "<b>Build URL</b> :- <a href=\"${BUILD_URL}console\">LINK</a>"
   	     echo "<b>Build time</b> :- $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
   	     echo
	     echo -e "<b>Status</b> :- Failed ❌"
	     echo -e "${DEVICE_MAINTAINERS} fix the error."
	  } > "${msg}"
   fi
   
   MESSAGE=$(cat "${msg}")
   TGlogs "$MESSAGE"
   sendTG "$MESSAGE"
}


