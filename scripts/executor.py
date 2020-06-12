#
# Copyright (C) 2020 PixysOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# PixysOS executor script.

import datetime, requests, json, os, jenkins

def count_builds(today, device):
  JENKINS_BUILDS_API = 'https://jenkins.pixysos.com/job/PixysOS-Ten/api/json?tree=builds[timestamp,actions[parameters[name,value]]]&pretty=true'
  api = requests.get(JENKINS_BUILDS_API)
  count = 0
  if api.status_code == 200:
    api = json.loads(api.text)
    for build in api['builds']:
      timestamp = build['timestamp']
      day = datetime.datetime.fromtimestamp(int(timestamp)/1000).strftime('%Y-%m-%d')
      if day == today:
        for action in build['actions']:
          if '_class' in action and action['_class'] == 'hudson.model.ParametersAction':
            for parameter in action['parameters']:
              if parameter['name'] == 'DEVICE':
                if device == parameter['value']:
                  count = count + 1
                  break
  return count

device = os.environ.get('device')
version = os.environ.get('version')
username = os.environ.get('username')
password = os.environ.get('password')
jenkins_url = 'https://' + username + ':' + password + '@jenkins.pixysos.com'
server = jenkins.Jenkins(jenkins_url)


targets_url = 'https://raw.githubusercontent.com/PixysOS/PixysOS_jenkins/ten/pixysos-build-targets'
targets = requests.get(targets_url).text
for target in targets.splitlines():
  if device in target:
    target = target.split(' ')
    allowed_day = target[1]
    allowed_count = target[2]
    break

current = datetime.datetime.now().strftime("%s")
today = datetime.date.fromtimestamp(int(current)).strftime('%Y-%m-%d')
day = datetime.date.fromtimestamp(int(current)).strftime('%A')[0:2]
count = count_builds(today, device)

if day == allowed_day and count <= int(allowed_count):
  server.build_job('PixysOS-Ten',{'DEVICE':device, 'pixys_edition':version})
  print('Build triggered. Find it on build job https://jenkins.pixysos.com/job/PixysOS-Ten/')
else:
  print('Build trigger failed. The requested device has either exceeded its quota or its not allowed to be made today.')
  print('Please refer to build targets https://github.com/PixysOS/PixysOS_jenkins/blob/ten/pixysos-build-targets')
