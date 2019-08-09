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

function TGlogs() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001322414571&parse_mode=Markdown" > /dev/null
}

function mirror() {
   mkdir temp
   cd temp
   git clone https://github.com/PixysOS-Devices/official_devices devices
   cd devices/${DEVICE}
   FILENAME=$(jq -r '.response[].filename' build.json)
   cd ../..
   wget https://downloads.pixysos.com/.test/${DEVICE}/${FILENAME}
   ZIP=$(ls PixysOS*.zip)
   export spass
   sshpass -p "${spass}" scp -o StrictHostKeyChecking=no "${ZIP}" pshreejoy15@frs.sourceforge.net:/home/frs/project/pixys-os/pie/${DEVICE}
   TGlogs "${FILENAME} has been mirrored to PixysOS [sourceforge portal](https://sourceforge.net/projects/pixys-os/files/pie/${DEVICE})"
   cd ..
   rm -rf temp
}

mirror
