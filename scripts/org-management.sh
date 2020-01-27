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

function remove-users() {
   [[ -z $users ]] && log "User add process aborted as users variable is empty" && exit 1
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
	     log "Fatal error: $user could not be removed from $repo_name"
	  fi
   done <<< "$users"
}

function telegram() {
   curl -s "https://api.telegram.org/bot${telegram_bot_token}/sendmessage" --data "text=${*}&chat_id=${chat_id}&parse_mode=HTML" > /dev/null  
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
   log "" # Empty log to break line
   log "####################################"
   paste_url=$(deldog "${log_file}")
   telegram "<b>Organization maintainance completed</b>

   <b>Status</b> : ${status}
   <b>Logs</b> : <a href=\"${paste_url}\">click-here</a>
   <b>Time taken</b> : ${t-taken} seconds"

  if [[ "$status" == "failed" ]]
  then 
     exit 1
  fi
  exit 0
}

function log() {
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
         log "$repo_name not found on ${org_name} GitHub organization, Creating $repo_name"
		 create-repo
		 [[ $user_action == "Add" ]] && add-users
	  elif [[ $user_action == "Remove" ]]
	  then
	     log "$repo_name not found on ${org_name} GitHub organization, Cannot remove user(s) $users"
		 status="failed" && exit-process
	  fi
   else
      log "$repo_name found on $org_name, Proceeding with further action"
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
      log "New repository created : <a href=\"https://github.com/${org_name}/$repo_name\">$repo_name</a>"
   else 
      log "Fatal error: Cannot create $repo_name" && exit 1
   fi
}

function delete-repo() {
   response=$(curl -X DELETE -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name")
   verify=$(jq -r '.name' <<< "$response")
   
   if [[ -n $verify ]] 
   then 
      log "New repository created : <a href=\"https://github.com/${org_name}/$repo_name\">$repo_name</a>"
   else 
      log "Fatal error: Cannot create $repo_name" && exit 1
   fi
}

function add-users() {
   [[ -z $users ]] && log "User add process aborted as users variable is empty" && exit 1
   while IFS= read -r user
   do
      user=$(echo -e "${user}" | tr -d '[:space:]')
	  response=$(curl -s https://api.github.com/users/"$user")
	  check=$(jq -r '.message' <<< "$response")
	  verify=$(jq -r '.login' <<< "$response")
	  if [[ $check != "Not Found" ]] && [[ $verify == "$user" ]]  && [[ -n $user ]]
	  then
	     response=$(curl -X PUT -H "Authorization: token ${github_token}" -s "https://api.github.com/repos/${org_name}/$repo_name/collaborators/$user")
	  else
	     log "Fatal error: $user could not be added to $repo_name"
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

while IFS= read -r repo_name
do
  log "############ $repo_name ############"
  check-repo
  log "####################################"
  log "" # Empty log for line break
  ####################
done <<< "$repo_names"
