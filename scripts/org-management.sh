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

function telegram() {
   curl -s "https://api.telegram.org/bot${telegram_bot_token}/sendmessage" --data "text=${*}&chat_id=${chat_id}&parse_mode=HTML"
}  
 
# Function to upload to del.dog
function deldog() {
    RESULT=$(curl -sf --data-binary @"${1:--}" https://del.dog/documents) || {
        echo "ERROR: failed to post document" >&2
        exit 1
    }
    KEY=$(jq -r .key <<< "${RESULT}")
    echo "https://del.dog/raw/${KEY}"
}

function exit-process() {
   paste_url=$(deldog "${log_file}")
   cat "${log_file}"
   BUILD_END=$(date +"%s")
   DIFF=$((BUILD_END - BUILD_START))
   telegram "<b>Organization maintainance completed</b>

   <b>Status</b> : ${status}
   <b>Logs</b> : <a href=\"${paste_url}\">click-here</a>
   <b>Time taken</b> : ${DIFF} seconds"

  if [[ "$status" == "failed" ]]
  then 
     exit 1
  fi
  exit 0
}

function log() {
   echo "${*}"
   echo "${*}" > "${log_file}"
}

function check-repo() {
   response=$(curl -X PUT -H "Authorization: token ${github_token}" -s https://api.github.com/repos/"${org_name}"/"$repo_name")
   check=$(jq -r '.message' <<< "$response")
   verify=$(jq -r '.name' <<< "$response")
   if [[ $check == "Not Found" ]] && [[ -z $verify ]]
   then
      if [[ $user_action == "Nothing" ]] || [[ $user_action == "Add" ]]
	  then
             log "$(date) => $repo_name not found on ${org_name} GitHub organization, Creating $repo_name"
	     create-repo
	     [[ $user_action == "Add" ]] && add-users
	  elif [[ $user_action == "Remove" ]]
	  then
	     log "$(date) => $repo_name not found on ${org_name} GitHub organization, Cannot remove user(s) $users"
	     status="failed"
	  fi
   else
      log "$(date) => $repo_name found on $org_name, Proceeding with further action"
      if [[ $repo_action == "Remove" ]]
	  then
	     delete-repo
	  fi
   fi	  
}

function create-repo() {
   response=$(curl -H "Authorization: token ACCESS_TOKEN" --data "name=$repo_name" https://api.github.com/orgs/"${org_name}"/repos)
   verify=$(jq -r '.name' <<< "$response")
   
   if [[ -n $verify ]] 
   then 
      log "$(date) => New repository created : <a href=\"https://github.com/${org_name}/$repo_name\">$repo_name</a>"
   else 
      log "$(date) => Fatal error: Cannot create $repo_name" && status="failed"
   fi
}

function delete-repo() {
   response=$(curl -X DELETE -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name")
   verify=$(jq -r '.name' <<< "$response")
   
   if [[ -n $verify ]] 
   then 
      log "$(date) => New repository created : <a href=\"https://github.com/${org_name}/$repo_name\">$repo_name</a>"
   else 
      log "$(date) => Fatal error: Cannot create $repo_name" && status="failed"
   fi
}

function add-users() {
   [[ -z $users ]] && log "$(date) => User add process aborted as users variable is empty" && status="failed"
   while IFS= read -r user
   do
      user=$(echo -e "${user}" | tr -d '[:space:]')
	  response=$(curl -s https://api.github.com/users/"$user")
	  check=$(jq -r '.message' <<< "$response")
	  verify=$(jq -r '.login' <<< "$response")
	  response=$(curl -X GET -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	  if [[ $check != "Not Found" ]] && [[ $verify == "$user" ]]  && [[ -n $user ]]
	  then
	     response=$(curl -X PUT -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	  else
	     log "$(date) => Fatal error: $user could not be added to $repo_name" && status="failed"
	  fi
   done <<< "$users"
}

function remove-users() {
   [[ -z $users ]] && log "$(date) => User add process aborted as users variable is empty" && status="failed"
   while IFS= read -r user
   do
      user=$(echo -e "${user}" | tr -d '[:space:]')
	  response=$(curl -s https://api.github.com/users/"$user")
	  check=$(jq -r '.message' <<< "$response")
	  verify=$(jq -r '.login' <<< "$response")
	  if [[ $check != "Not Found" ]] && [[ $verify == "$user" ]]  && [[ -n $user ]]
	  then
	     response=$(curl -X DELETE -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	  else
	     log "$(date) => Fatal error: $user could not be removed from $repo_name" && status="failed"
	  fi
   done <<< "$users"
}

 
# Organization details
org_name="PixysOS-Devices"
# Repository details
repo_names="${1}"
repo_action="${2}"
# Users details
users=${3}
user_action=${4}
# Extra details
github_token=${5}
telegram_bot_token=${6}
chat_id=${7}
status="passed"
# Log file details
log_file=$(mktemp)
console_dump=$(mktemp)

BUILD_START=$(date +"%s")
while IFS= read -r repo_name
do
  log "$(date) => Starting process for $repo_name"
  check-repo
done <<< "$repo_names"
exit-process
