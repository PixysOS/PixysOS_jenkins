#!/usr/bin/env bash
#
# Copyright (C) 2019 PixysOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# PixysOS ROM Sync Source Script.

command="$1"

if [ "$command" == "Repo Initialization" ];
   then
       export repo=".repo"
       if [ ! -d "$repo" ];
       then
             echo -e "Initializing The Repo"
             repo init -u https://github.com/PixysOS/manifest.git -b pie
             sleep 5
             echo -e "Repo has been Initialized, please sync the source"
	   fi
	   echo -e "Repo Already Initialized, please Remove the .repo Directory or Just Start Sync The Source";
fi


if [ "$command" == "Json" ];
   then
       export DIRECTORY=json;
       if [ ! -d "$DIRECTORY" ];
       then
             echo -e "Creating json Directory"
       	     mkdir "$DIRECTORY" ;
			 echo -e "Json Directory Created"
       fi
	   echo -e "json Directory Already Exist, Exiting Now.";
fi

if [ "$command" == "Sync Source" ];
   then
        echo -e "Syncing Source, will take Little Time."
		repo sync --force-sync -j48 --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune
		wait
		echo "Source Synced Successfully"
fi

if [ "$command" == "Sync Source and Json" ];
   then
        echo -e "Syncing Source, will take Little Time."
		repo sync --force-sync -j48 --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune
		wait
		echo -e "Source Synced Successfully"
		mkdir json
		echo -e "Json Directory Created"
fi
