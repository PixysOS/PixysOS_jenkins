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
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001144148166&parse_mode=Markdown" > /dev/null
}

function mirror() {
   wget https://downloads.pixysos.com/.test/${DEVICE}/${FILENAME}
   ZIP=$(ls PixysOS*.zip)
   export spass
   export opass
   sshpass -p "${opass}" scp -P 5615 -o StrictHostKeyChecking=no "${ZIP}" root@uploads.pixysos.com:/home/ftp/uploads/${DEVICE}/ten/
   TGlogs "${FILENAME} has been Uploaded to PixysOS [official download portal](https://downloads.pixysos.com/${DEVICE}/ten/)"
   sshpass -p "${spass}" scp -o StrictHostKeyChecking=no "${ZIP}" pixysuploads@frs.sourceforge.net:/home/frs/project/pixys-os/ten/${DEVICE}/
   TGlogs "${FILENAME} has been mirrored to PixysOS [sourceforge portal](https://sourceforge.net/projects/pixys-os/files/ten/${DEVICE})"
   rm -rf *.zip
}

mirror
