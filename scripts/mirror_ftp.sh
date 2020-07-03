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

DEVICE=${1}
FILENAME=${2}

export spass bottoken

function TG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001144148166&parse_mode=HTML" > /dev/null
}

function mirror() {
   echo "$FILENAME" | grep -q "GAPPS" && FOLDER="ten_gapps" || FOLDER="ten"
   TG "Initializing the release of <code>${FILENAME}</code> for device. View progress <a href=\"${BUILD_URL}\">here</a>"
   cp /home/ftp/uploads/.test/"${DEVICE}"/${FOLDER}/"${FILENAME}" /home/ftp/ft-uploads/
   CHECK=$(ls PixysOS*.zip)
   [ "${CHECK}" == "${FILENAME}" ] && echo "${FILENAME} found, Starting upload process" || TG "$FILENAME cannot be downloaded correctly"
   mkdir -p /home/ftp/uploads/"${DEVICE}"/ten/
   mv /home/ftp/uploads/.test/"${DEVICE}"/${FOLDER}/"${FILENAME}" /home/ftp/uploads/"${DEVICE}"/ten/
   lftp sftp://pixysuploads:${spass}@frs.sourceforge.net -e "mkdir -f /home/frs/project/pixys-os/ten/${DEVICE}; bye"
   sshpass -p "${spass}" scp -o StrictHostKeyChecking=no "${FILENAME}" pixysuploads@frs.sourceforge.net:/home/frs/project/pixys-os/ten/"${DEVICE}"/
   git clone git@github.com:PixysOS-Devices/official_devices -b ten
   cd official_devices
      mkdir -p ${DEVICE}
      if [ $FOLDER = "ten"];
      then
         cp -rf /home/ftp/uploads/.test/"${DEVICE}"/${FOLDER}/"${DEVICE}.json" "${DEVICE}/build.json"
      elif [ $FOLDER = "ten_gapps"];
      then
         cp -rf /home/ftp/uploads/.test/"${DEVICE}"/${FOLDER}/"${DEVICE}.json" "${DEVICE}/gapps_build.json"
      fi
      git add .
      git commit -m "official_devices: ${DEVICE} (${FOLDER}) update"
      git push
   cd ..
   wget https://raw.githubusercontent.com/PixysOS/PixysOS_jenkins/ten/scripts/post_message.py
   pip3 install python-telegram-bot
   python3 post_message.py
   rm -rf *.zip official_devices post_message.py
}

mirror
