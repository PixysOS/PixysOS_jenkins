#
# Copyright (C) 2020 PixysOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# PixysOS executor script.

import os, datetime
from github import Github

evar = os.environ.copy()
username = evar["username"]
password = evar["password"]
telegram_bot_token = evar["telegram_bot_token"]

global repo_names = evar["repo_names"]
global repo_action = evar["repo_action"]
global user_names = evar["user_names"]
global user_action = evar["user_action"]

logs = ""
def logger(log):
  log = time_now() + ' => ' + log
  print(log)
  logs = logs + '\n' + log

def time_now():
  return datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
  
def check_repo():
  try:
    repo_name = 'PixysOS-Devices/' + repo_name
    auth.get_repo(repo)
  except:
    
    
for repo_name in repo_names.splitlines():
  logger('Starting process for ' + repo_name)
  try:
    auth.get_repo(repo)
  except:
    if repo_action == 'delete':
      repo_name = 'PixysOS-Devices/' + repo_name
      logger(repo_name + 'not found on PixysOS-Devices organization, delete action aborted')
      continue
    else:
      logger(repo_name + 'not found on PixysOS-Devices organization, Creating repository')
      auth.get_organization('PixysOS-Devices').create_repo(repo_name)
      repo_name = 'PixysOS-Devices/' + repo_name
      
  cs = auth.get_repo(reponame).get_collaborators()
  collaborators = []
  
  for c in cs:
    collaborators.append(c)
    
  if user_action == 'delete':
    for user_name in user_names:
        if user_name in collaborators:
          # TO BE COMPLETED
  
    
    
    
    
