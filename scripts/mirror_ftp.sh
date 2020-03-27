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
   wget https://downloads.pixysos.com/.test/"${DEVICE}"/${FOLDER}/"${FILENAME}"
   CHECK=$(ls PixysOS*.zip)
   [ "${CHECK}" == "${FILENAME}" ] && echo "${FILENAME} found, Starting upload process" || TG "$FILENAME cannot be downloaded correctly"
   scp -P 5615 -o StrictHostKeyChecking=no "${FILENAME}" ftp@uploads.pixysos.com:/home/ftp/uploads/"${DEVICE}"/ten/
   sshpass -p "${spass}" scp -o StrictHostKeyChecking=no "${FILENAME}" pixysuploads@frs.sourceforge.net:/home/frs/project/pixys-os/ten/"${DEVICE}"/
   TG "${FILENAME} has been uploaded to <a href=\"https://downloads.sourceforge.net/project/pixys-os/ten/${DEVICE}/${FILENAME}\">Sourceforge</a> and <a href=\"https://downloads.pixysos.com/${DEVICE}/ten/${FILENAME}\">FTP</a>"
   rm -rf *.zip
}

mirror
