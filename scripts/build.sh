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
   export DJSON="https://raw.githubusercontent.com/PixysOS-Devices/official_devices/master/devices.json"
   export DEVICE_MAINTAINERS=$(jq -r --arg DEVICE "$DEVICE" '.[] | select(.codename==$DEVICE) | .maintainer_name' <<< ${DJSON}) # The maintainer of that device
   export KBUILD_BUILD_USER=${DEVICE_MAINTAINERS}
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
       git clone --recurse-submodules --depth=1 --quiet $repo_url -b $branch $target
       printf "${Color_Off}"
       if [ -e /home/pixys/source/$target ]
          then
             printf "\n${Green}Repo clone success...\n${Color_Off}"
             echo "$target" >> /home/pixys/source/clone_path.txt
           else
             sendTG "Could not clone some dependecies for [$DEVICE]($BUILD_URL)"
	         TGlogs "Could not clone some dependecies for [$DEVICE]($BUILD_URL)"
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
    TGlogs "Starting build for [$DEVICE]($BUILD_URL) on ${NODE_NAME}"
    sendTG "Starting build for [$DEVICE]($BUILD_URL) on ${NODE_NAME}"
    make bacon -j24
    BUILD_END=$(date +"%s")
    BUILD_TIME=$(date +"%Y%m%d-%T")
    DIFF=$((BUILD_END - BUILD_START))
}
   
	  
function build_end() {
   if [ -f /home/pixys/source/out/target/product/$DEVICE/PixysOS*.zip ]
   then
      cd /home/pixys/source/out/target/product/$DEVICE
      ZIP=$(ls PixysOS*.zip)
	  JSON="${DEVICE}.json"
	  status="passed"
	  build_json
      upload_ftp
   else
      status="failed"
	  upload_ftp
      exit 1
   fi
}

wget -O /home/pixys/source/extra.sh https://raw.githubusercontent.com/PixysOS/PixysOS_jenkins/master/scripts/extra.sh
source /home/pixys/source/extra.sh
DEVICE="$1" # Enter the codename of the device
use_ccache="$2" # Ccache time
clean_device="$3" # if the device is different from last one
make_clean="$4" # make a clean build or not 
upload="$5"

exports
use_ccache
clean_up
build_main
upload_ftp
build_end
