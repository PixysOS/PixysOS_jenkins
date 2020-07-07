#!/usr/bin/env bash

lunch_command="$1"
device="$2"
source build/envsetup.sh
lunch "${lunch_command}"
make bacon -j24

if [ -f out/target/product/"$device"/PixysOS*.zip ];then
  current=$(pwd)
  cd /home/pixys/source/out/target/product/"$device" || exit
  zip=$(ls PixysOS*.zip)
  echo "$FILENAME" | grep -q "GAPPS" && edition="ten_gapps" || edition="ten"
  ftp="/home/ftp/uploads/.test/$device/$edition"
  echo "Copying build artifacts to ftp server...."
  lftp -p 5615 sftp://ftp:ftp@uploads.pixysos.com -e "rm -rf $ftp; mkdir -f $ftp; cd $ftp; put $zip; bye"
  
  datetime=$(cat system/build.prop | grep ro.pixys.build.date | cut -d'=' -f2)
  filename=$(stat -c %n "${zip}" | sed 's/.*\///')
  name=$(cat system/build.prop | grep ro.pixys.version | cut -d'=' -f2)
  id=$(md5sum "${zip}" | cut -d " " -f 1)
  size=$(cat "${zip}" | wc -c)
  version=$(cat system/build.prop | grep ro.modversion | cut -d'=' -f2)
  echo -ne "{" > "$name".json
  echo -ne "\n   \"device\": \"$device\"," >> "$name".json
  echo -ne "\n   \"edition\": \"$edition\"," >> "$name".json
  echo -ne "\n   \"version\": \"$version\"," >> "$name".json
  echo -ne "\n   \"filename\": \"$filename\"," >> "$name".json
  echo -ne "\n   \"datetime\": \"$datetime\"," >> "$name".json
  echo -ne "\n   \"id\": \"$id\"," >> "$name".json
  echo -ne "\n   \"size\": \"$size\"," >> "$name".json
  echo -ne "\n}" >> "$name".json
  
  echo "Copying OTA configs to ftp server...." 
  lftp -p 5615 sftp://ftp:ftp@uploads.pixysos.com -e "cd $ftp; put $name.json; bye"
  exit 0
else
  exit 1
fi
