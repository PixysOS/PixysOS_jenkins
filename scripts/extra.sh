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
   MAIN_URL="https://downloads.sourceforge.net/project/pixys-os/ten/${DEVICE}/${ZIP}"
   mode_version=$(cat system/build.prop | grep ro.modversion | cut -d'=' -f2)
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
      echo -e "      \x22version\x22: ${mode_version}"
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
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001144148166&parse_mode=HTML" > /dev/null
}

# Additonal function to used in future versions
function TG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=${chat_id}&parse_mode=Markdown" > /dev/null
}

#function to connect to ssh 
function sshc() {
  ssh -p 5615 -o StrictHostKeyChecking=no ftp@uploads.pixysos.com "${1}"
}

#function to make scp upload
function scpc() {
  scp -P 5615 -o StrictHostKeyChecking=no "${1}" ftp@uploads.pixysos.com:/home/ftp/uploads/.test/"${DEVICE}"/"${FTP_FOLDER}"
}

function upload_ftp() {
   msg=$(mktemp)
   if [ "$status" == "passed" ]
   then 
      if [ "$upload" == "true" ]
      then
         basic="http://downloads.pixysos.com/.test/${DEVICE}/${FTP_FOLDER}/${ZIP}"
         echo -e "Uploading test artifact ${ZIP}"
         sshc "rm -rf /home/ftp/uploads/.test/${DEVICE}/${FTP_FOLDER}"
         sshc "mkdir /home/ftp/uploads/.test/${DEVICE}/${FTP_FOLDER}"
         scpc "${ZIP}"
         scpc "${JSON}"
	 {
	     echo "🏷 <b>Build Completed</b>"
   	     echo 
   	     echo "<b>Device</b> :- #${DEVICE}"
   	     echo "<b>Build URL</b> :- <a href=\"${BUILD_URL}console\">LINK</a>"
	     echo "<b>Version</b> :- ${FTP_FOLDER}"
   	     echo "<b>Build time</b> :- $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
   	     echo
   	     echo "<b>Status</b> :- Passed ✅"
   	     echo "⬇️ <a href=\"${basic}\">Download</a>"
	  } > "${msg}"
       elif [ "$upload" == "false" ]
       then
 	 {
	     echo "🏷 <b>Build Completed</b>"
   	     echo 
   	     echo "<b>Device</b> :- #${DEVICE}"
   	     echo "<b>Build URL</b> :- <a href=\"${BUILD_URL}console\">LINK</a>"
	     echo "<b>Version</b> :- ${FTP_FOLDER}"
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
	     echo "<b>Version</b> :- ${FTP_FOLDER}"
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
