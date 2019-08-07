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
sshpass -p "${spass}" ssh -p 5615 -o StrictHostKeyChecking=no root@pixys.shreejoydash.me

cd /home/ftp/uploads

if [ -f .test/${DEVICE} ];
then 
   cd .test/${DEVICE}
   mv PixysOS*.zip /home/ftp/uploads/${DEVICE}
   cd /home/ftp
   git clone https://github.com/PixysOS-Devices/official_devices temp
   cd temp 
   cd ${DEVICE}
   cp /home/ftp/uploads/.test/${DEVICE}/${DEVICE}.json /home/ftp/temp/${DEVICE}
   rm -rf build.json
   mv ${DEVICE}.json build.json
fi
   
