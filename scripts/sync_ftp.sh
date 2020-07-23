#!/usr/bin/env bash
[[ ! -z "${CHANGED}" ]] && echo "Telegram API_KEY not defined, exiting!" && exit 1

function sendTG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001383679787&parse_mode=HTML" > /dev/null
    echo "${*}"
}

git clone ssh://git@github.com/PixysOS-Devices/FTP-files
cd FTP-files
rm -rf *
rclone tree --all --full-path --human --noindent --output filelist_no_indent.txt ${primary_mirror}:
rclone tree --all --full-path --human --output filelist_indent.txt ${primary_mirror}:
export CHANGED=$(git diff --stat | tail -n1)
if [[ -z "${CHANGED}" ]]; then
    echo "No files changed on the primary remote, exiting!"
    cd .. && rm -rf FTP-files
    exit 0
else
    echo "Some files changed, beginning to sync the mirrors"

sendTG "Syncing local storage to global mirrors. View conole => ${BUILD_URL}"
BUILD_START=$(date +"%s")
for i in "${arr[@]}"
do
   echo "Sync started for mirror= > $i"
   rclone --progress sync ${primary_mirror}: "$i":
done
BUILD_END=$(date +"%s")
DURATION=$((BUILD_END - BUILD_START))
DATE=$(date)

read -r -d '' msg <<EOT
<b>Syncing all the mirrors</b>

<b>Date =</b> $DATE
<b>Duration =</b> $DURATION seconds
<b>DIFF =</b> $CHANGED
EOT

echo "All global mirrors have been synced properly.."
echo "Sending filelist...."
git commit -m "Sync: $DATE"
git push
cd ..
rm -rf FTP-files
