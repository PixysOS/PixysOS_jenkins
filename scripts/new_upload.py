from github import Github
from requests import get
from json import loads, dumps
from argparse import ArgumentParser

switches = ArgumentParser()
switches.add_argument("--device", required=True, help="Codename")
switches.add_argument("--filename", required=True, help="Filename")

# arguments
args = vars(switches.parse_args())
device = args["device"]
filename = args["filename"]
edition = 'ten_gapps' if 'GAPPS' in filename else 'ten'

auth = Github()
official_builds = auth.get_repo('PixysOS-Devices/official_builds')
official_devices = auth.get_repo('PixysOS-Devices/official_devices')
#lftp_sourceforge_command = 'cd /home/frs/project/pixys-os/ten; mkdir device; put .test'
#lftp_server_command = 'cd uploads; mkdir ' + device + '; mmv .test/' + device + '/' + edition' /' + filename + ' ' + device + '/ten';' 
#subprocess.call(['lftp','sftp://ftp:ftp@uploads.pixysos.com:5615','-e','cd uploads;bye'])
