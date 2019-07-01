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

function colors() {
   export TERM=xterm
   bash color.sh
}

function exports() {
   export PIXYS_BUILD_PATH=/home/pixys/source
   export PIXYS_BUILD_TYPE=OFFICIAL
   export KBUILD_BUILD_HOST="PixysBuildBot"
   export KBUILD_BUILD_USER=${DEVICE_MAINTAINER}
}

function TGlogs() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001322414571&parse_mode=Markdown" > /dev/null
}

function sendTG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001239809576&parse_mode=Markdown" > /dev/null
}

function clean_up() {
    # Its Clean Time
   if [ "$make_clean" = "true" ]
   then
      make clean && make clobber
   elif [ "$make_clean" = "false" ]
   then
      rm -rf out/target/product/*
      wait
      echo -e ${Cyan}"OUT dir from your repo deleted"${Color_Off};
   else
      echo "No need to clean"
   fi
   # Clean old device dependencies
   if [ "$clean_device" = "true" ];
   then
      if [ -e /home/pixys/source/clone_path.txt ];
      then
         clone_path=$(cat /home/pixys/source/clone_path.txt)
         if [ -z ${clone_path} ];
         then
            echo "clone_path.txt is empty so nothing to wipe"
         else
            for WORD in `cat /home/pixys/source/clone_path.txt`
            do
              printf "${Blue}Deleting obsolete path /home/pixys/source/${WORD}\n${Color_Off}"
              rm -rf $WORD
            done
            rm -rf /home/pixys/source/clone_path.txt
            touch /home/pixys/source/clone_path.txt
         fi
    else
        echo "clone_path.txt doesnt exist"
        touch /home/pixys/source/clone_path.txt
    fi
    build_init
   fi
}

function build_init() {
    rm -rf /home/pixys/source/json/"${DEVICE}".json
    rm -rf /home/pixys/source/devices_dep.json
    wget -O /home/pixys/source/devices_dep.json -q https://raw.githubusercontent.com/PixysOS/PixysOS_jenkins/master/devices_dep.json
    jq --arg DEVICE "$DEVICE" '. | .[$DEVICE]' /home/pixys/source/devices_dep.json > /home/pixys/source/json/"${DEVICE}".json
    export dep_count=$(jq length /home/pixys/source/json/${DEVICE}.json)
    printf "\n${UYellow}Cloning device specific dependencies \n\n${Color_Off}"
    for ((i=0;i<${dep_count};i++));
    do
       repo_url=$(jq -r --argjson i "$i" '.[$i].url' /home/pixys/source/json/${DEVICE}.json)
       branch=$(jq -r --argjson i "$i" '.[$i].branch' /home/pixys/source/json/${DEVICE}.json)
       target=$(jq -r --argjson i "$i" '.[$i].target_path' /home/pixys/source/json/${DEVICE}.json)
       printf "\n>>> ${Blue}Cloning to $target...\n${Color_Off}\n"
       git clone --depth=1 --quiet $repo_url -b $branch $target
       printf "${Color_Off}"
       if [ -e /home/pixys/source/$target ]
          then
             printf "\n${Green}Repo clone success...\n${Color_Off}"
             echo "$target" >> /home/pixys/source/clone_path.txt
           else
             sendTG "Could not clone some dependecies for [$DEVICE]($BUILD_URL)"
             TGlogs "Build for $DEVICE Failed due to dep issues"
             printf "\n\n${Red}Repo clone fail...\n\n${Color_Off}"
             printf "${Cyan}Exiting${Color_Off}"
             sleep 5
             exit 1
            fi
    done
}

function build_main() {
    cd /home/pixys/source
    BUILD_START=$(date +"%s")
    source build/envsetup.sh
    lunch pixys_${DEVICE}-userdebug
    printf "${BICyan}Starting build for ${DEVICE}${Color_Off}"
    TGlogs "Build for $DEVICE started"
    sendTG "Starting build for [$DEVICE]($BUILD_URL) on ${NODE_NAME}"
    make bacon -j24
    BUILD_END=$(date +"%s")
    BUILD_TIME=$(date +"%Y%m%d-%T")
    DIFF=$((BUILD_END - BUILD_START))
}
function upload_ftp() {
   if [ -f /home/pixys/source/out/target/product/$DEVICE/PixysOS*.zip ]
   then
   TGlogs "#${DEVICE} build passed"
   cd /home/pixys/source/out/target/product/$DEVICE
       ZIP=$(ls PixysOS*.zip)
       printf "${Yellow}Uploading test artifact ${ZIP}${Color_Off}"
       LINK="http://downloads.pixysos.com/.test/${DEVICE}/${ZIP}"
       printf "${Green}Build for $DEVICE completed successfully\n${Color_Off}"
       ssh -p 5615 -o StrictHostKeyChecking=no root@downloads.pixysos.com "rm -rf /home/ftp/uploads/.test/${DEVICE}"
       ssh -p 5615 -o StrictHostKeyChecking=no root@downloads.pixysos.com "mkdir /home/ftp/uploads/.test/${DEVICE}"
       scp -P 5615 -o StrictHostKeyChecking=no ${ZIP} root@downloads.pixysos.com:/home/ftp/uploads/.test/${DEVICE}
       sendTG "Build for [$DEVICE]($BUILD_URL) passed on ${NODE_NAME} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
       sendTG "Maintainer of $DEVICE, Please test [$ZIP]($LINK) and inform administrator if its ready for the release."
    else
        sendTG "Build for [$DEVICE]($BUILD_URL) failed on ${NODE_NAME} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
        TGlogs "#${DEVICE} build failed"
     exit 1
    fi
}

DEVICE="$1" # Enter the codename of the device
DEVICE_MAINTAINER="$2" # The maintainer of that device
clean_device="$3" # if the device is different from last one
make_clean="$4" # make a clean build or not 

colors
exports
clean_up
build_main
upload_ftp
