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
   MAIN_URL="https://download.pixysos.com/${DEVICE}/${ZIP}"
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
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001322414571&parse_mode=Markdown" > /dev/null
}

#function to send messages on maintainers group
function sendTG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001239809576&parse_mode=Markdown" > /dev/null
}

# Function to upload to del.dog
function deldog() {
    RESULT=$(curl -sf --data-binary @"${1:--}" https://del.dog/documents) || {
        echo "ERROR: failed to post document" >&2
        exit 1
    }
    KEY=$(jq -r .key <<< "${RESULT}")
    echo "https://del.dog/${KEY}"
    echo "https://del.dog/raw/${KEY}"
}

function upload_ftp() {
   msg=$(mktemp)
   if [ "$status" == "passed" ]
   then 
      if [ "$upload" == "true" ]
      then
         DL_LINK="http://downloads.pixysos.com/.test/${DEVICE}/${ZIP}"
         printf "\n\nUploading test artifact ${ZIP}\n"
         ssh -p 5615 -o StrictHostKeyChecking=no root@pixys.shreejoydash.me "rm -rf /home/ftp/uploads/.test/${DEVICE}"
         ssh -p 5615 -o StrictHostKeyChecking=no root@pixys.shreejoydash.me "mkdir /home/ftp/uploads/.test/${DEVICE}"
         scp -P 5615 -o StrictHostKeyChecking=no "${ZIP}" root@pixys.shreejoydash.me:/home/ftp/uploads/.test/"${DEVICE}"
         scp -P 5615 -o StrictHostKeyChecking=no "${JSON}" root@pixys.shreejoydash.me:/home/ftp/uploads/.test/"${DEVICE}"
	 {
             echo -e "🏷 *Build Completed*"
             echo 
             echo -e "Device :- #${DEVICE}"
             echo -e "Build URL :- [LINK](${BUILD_URL}/console)"
             echo -e "Build time :- $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
             echo 
             echo -e "*Status* :- Passed ✅"
	     echo -e "⬇️[Download](${DL_LINK})"
	  } > "${msg}"
       else 
 	 {
             echo -e "🏷 *Build Completed*"
             echo 
             echo -e "Device :- #${DEVICE}"
             echo -e "Build URL :- [LINK](${BUILD_URL}/console)"
             echo -e "Build time :- $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
             echo 
             echo -e "*Status* :- Passed ✅"
	  } > "${msg}"
       fi
    else
 	  {
             echo -e "🏷 *Build Completed*"
             echo 
             echo -e "Device :- #${DEVICE}"
             echo -e "Build URL :- [LINK](${BUILD_URL}/console)"
             echo -e "Build time :- $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
             echo 
	     echo -e "*Status* :- Failed ❌"
	     echo -e "${DEVICE_MAINTAINERS} fix the error."
	  } > "${msg}"
   fi
   
   MESSAGE=$(cat "${msg}")
   TGlogs "$MESSAGE"
   sendTG "$MESSAGE"
}
