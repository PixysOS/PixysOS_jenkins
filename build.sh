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

function exports() {
   export PIXYS_BUILD_PATH=/home/pixys/source
   export PIXYS_BUILD_TYPE=OFFICIAL
   export KBUILD_BUILD_HOST="PixysBuildBot"
   export DEVICE_MAINTAINERS="${DEVICE_MAINTAINER}"
   export KBUILD_BUILD_USER=${DEVICE_MAINTAINER}
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
    RESULT=$(curl -sf --data-binary @${1:--} https://del.dog/documents) || {
        echo "ERROR: failed to post document" >&2
        exit 1
    }
    KEY=$(jq -r .key <<< ${RESULT})
    echo "https://del.dog/${KEY}"
    echo "https://del.dog/raw/${KEY}"
}

function use_ccache() {
    # CCACHE UMMM!!! Cooks my builds fast
   if [ "$use_ccache" = "yes" ];
   then
      printf "CCACHE is enabled for this build"
      export USE_CCACHE=1
      export CCACHE_DIR=/home/subins/ccache/pixys
      prebuilts/misc/linux-x86/ccache/ccache -M 50G
    elif [ "$use_ccache" = "clean" ];
    then
       export CCACHE_DIR=/home/subins/ccache/pixys
       ccache -C
       export USE_CCACHE=1
       prebuilts/misc/linux-x86/ccache/ccache -M 50G
       wait
       printf "CCACHE Cleared"
    fi
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
      echo -e "OUT dir from your repo deleted";
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
              printf "Deleting obsolete path /home/pixys/source/${WORD}\n"
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
    printf "\nCloning device specific dependencies \n\n"
    for ((i=0;i<${dep_count};i++));
    do
       repo_url=$(jq -r --argjson i "$i" '.[$i].url' /home/pixys/source/json/${DEVICE}.json)
       branch=$(jq -r --argjson i "$i" '.[$i].branch' /home/pixys/source/json/${DEVICE}.json)
       target=$(jq -r --argjson i "$i" '.[$i].target_path' /home/pixys/source/json/${DEVICE}.json)
       printf "\n>>> Cloning to $target...\n\n"
       git clone --recurse-submodules --depth=1 --quiet $repo_url -b $branch $target
       printf "${Color_Off}"
       if [ -e /home/pixys/source/$target ]
          then
             printf "\nRepo clone success...\n"
             echo "$target" >> /home/pixys/source/clone_path.txt
           else
             sendTG "Could not clone some dependecies for [$DEVICE]($BUILD_URL)"
	     TGlogs "Could not clone some dependecies for [$DEVICE]($BUILD_URL)"
             printf "\n\nRepo clone fail...\n\n"
             printf "Exiting in 5secs"
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
    printf "Starting build for ${DEVICE}"
    TGlogs "Starting build for [$DEVICE]($BUILD_URL) on ${NODE_NAME}"
    sendTG "Starting build for [$DEVICE]($BUILD_URL) on ${NODE_NAME}"
    make bacon -j24
    BUILD_END=$(date +"%s")
    BUILD_TIME=$(date +"%Y%m%d-%T")
    DIFF=$((BUILD_END - BUILD_START))
}
function upload_ftp() {
   if [ -f /home/pixys/source/out/target/product/$DEVICE/PixysOS*.zip ]
   then

   cd /home/pixys/source/out/target/product/$DEVICE
       ZIP=$(ls PixysOS*.zip)
       DL_LINK="http://downloads.pixysos.com/.test/${DEVICE}/${ZIP}"
       printf "Uploading test artifact ${ZIP}"
       ssh -p 5615 -o StrictHostKeyChecking=no root@downloads.pixysos.com "rm -rf /home/ftp/uploads/.test/${DEVICE}"
       ssh -p 5615 -o StrictHostKeyChecking=no root@downloads.pixysos.com "mkdir /home/ftp/uploads/.test/${DEVICE}"
       scp -P 5615 -o StrictHostKeyChecking=no ${ZIP} root@downloads.pixysos.com:/home/ftp/uploads/.test/${DEVICE}
       sendTG "Build for [$DEVICE]($BUILD_URL) passed on ${NODE_NAME} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
       sendTG "Maintainer of $DEVICE, Please test [$ZIP](${DL_LINK}) and inform administrator if its ready for the release."
       TGlogs "Build for [$DEVICE]($BUILD_URL) passed on ${NODE_NAME} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
       TGlogs "Maintainer of $DEVICE, Please test [$ZIP](${DL_LINK}) and inform administrator if its ready for the release."
    else
        sendTG "Build for [$DEVICE]($BUILD_URL) failed on ${NODE_NAME} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
	TGlogs "Build for [$DEVICE]($BUILD_URL) failed on ${NODE_NAME} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds."
     exit 1
    fi
}

DEVICE="$1" # Enter the codename of the device
DEVICE_MAINTAINER="$2" # The maintainer of that device
use_ccache="$3" # Ccache time
clean_device="$4" # if the device is different from last one
make_clean="$5" # make a clean build or not 

colors
exports
use_ccache
clean_up
build_main
upload_ftp
