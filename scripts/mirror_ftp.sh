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

export spass opass bottoken

function TG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001144148166&parse_mode=HTML" > /dev/null
}

function odlink() {
    fileid=$(rclone link Onedrive:Pixysos-test/"${DEVICE}"/"${FOLDER}"/"${FILENAME}" | cut -c 19-)
    link="http://seleniums.herokuapp.com/try/${fileid}/dl"
}

function mirror() {
   echo "$FILENAME" | grep -q "GAPPS" && FOLDER="ten_gapps" || FOLDER="ten"
   rclone copy Onedrive:Pixysos-test/"${DEVICE}"/"${FOLDER}"/"${FILENAME}" "${FILENAME}"
   CHECK=$(ls PixysOS*.zip)
   [ "${CHECK}" == "${FILENAME}" ] && echo "${FILENAME} found, Starting upload process" || TG "$FILENAME cannot be downloaded correctly"
   sshpass -p "${opass}" scp -P 5615 -o StrictHostKeyChecking=no "${FILENAME}" root@uploads.pixysos.com:/home/ftp/uploads/"${DEVICE}"/ten/
   sshpass -p "${spass}" scp -o StrictHostKeyChecking=no "${FILENAME}" pixysuploads@frs.sourceforge.net:/home/frs/project/pixys-os/ten/"${DEVICE}"/
   rclone copy "${FILENAME}" Onedrive:PixysOS/"${DEVICE}"/"${FOLDER}"/
   odlink
   TG "${FILENAME} has been uploaded to <a href=\"https://downloads.sourceforge.net/project/pixys-os/ten/${DEVICE}/${FILENAME}\">Sourceforge</a>, <a href=\"https://downloads.pixysos.com/${DEVICE}/ten/${FILENAME}\">FTP</a> and <a href=\"${link}\">OneDrive</a>"
   rm -rf *.zip
}

mirror
