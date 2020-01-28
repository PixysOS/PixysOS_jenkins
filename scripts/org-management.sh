#!/usr/bin/env bash
#
# Copyright (C) 2019-20 PixysOS project.
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
   response=$(curl -X GET -H "Authorization: token ${github_token}" -s https://api.github.com/repos/"${org_name}"/"$repo_name")
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
   response=$(curl -X POST -H "Authorization: token ${github_token}" --data '{ "name":"'"$repo_name"'"}' https://api.github.com/orgs/"${org_name}"/repos)
   verify=$(jq -r '.name' <<< "$response")
   
   if [[ -n $verify ]] 
   then 
      log "$(date) => New repository created : https://github.com/${org_name}/$repo_name"
   else 
      log "$(date) => Fatal error: Cannot create $repo_name" && status="failed"
   fi
}

function delete-repo() {
   response=$(curl -X DELETE -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name")
   # Check if the repo is deleted or not.
   response=$(curl -X GET -H "Authorization: token ${github_token}" -s https://api.github.com/repos/"${org_name}"/"$repo_name")
   check=$(jq -r '.message' <<< "$response")
   verify=$(jq -r '.name' <<< "$response")
   if [[ $check == "Not Found" ]] && [[ -z $verify || $verify == "null" ]]
   then
       log "$(date) => Repository named \"${repo_name}\" deleted successfully from ${org_name} GitHub Organization"
   else
       log "$(date) => Fatal error deleting \"${repo_name}\" from ${org_name} GitHub Organization"
   fi      
}

function add-users() {
   while IFS= read -r user
   do
      user=$(echo -e "${user}" | tr -d '[:space:]')
      if [[ -n $user ]]
      then
         response=$(curl -s https://api.github.com/users/"$user")
	 check=$(jq -r '.message' <<< "$response")
	 verify=$(jq -r '.login' <<< "$response")
	 if [[ $check != "Not Found" ]] && [[ $verify == "$user" ]]
	 then
	  response=$(curl -X GET -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	  verify=$(jq -r '.message' <<< "$response")
	  if [[ $verify == "Not Found" ]]
	  then
	     response=$(curl -X PUT -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	     log "$(date) => \"$user\" has been invited as a collaborater in \"$repo_name\" repository."
	  else
	     log "$(date) => Warning: \"$user\" is already a collaborater in \"$repo_name\" repository.  Process \"add-users\" aborted"
	  fi
   done <<< "$users"
}

function remove-users() {
   while IFS= read -r user
   do
      user=$(echo -e "${user}" | tr -d '[:space:]')
      if [[ -n $user ]]
      then
         response=$(curl -s https://api.github.com/users/"$user")
	 check=$(jq -r '.message' <<< "$response")
	 verify=$(jq -r '.login' <<< "$response")
	 if [[ $check != "Not Found" ]] && [[ $verify == "$user" ]]
	 then
	  response=$(curl -X GET -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	  verify=$(jq -r '.message' <<< "$response")
	  if [[ $verify != "Not Found" ]]
	  then
	     response=$(curl -X DELETE -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	     log "$(date) => \"$user\" has been removed from collaboraters in \"$repo_name\" repository."
	  else
	     log "$(date) => Warning: \"$user\" is not a collaborater in \"$repo_name\" repository. Process \"remove-users\" aborted"
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
