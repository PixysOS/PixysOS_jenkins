import json
import rclone
import requests
import wget

onedrive_cfg_url = os.environ("onedrive_cfg_url")
onedrive_cfg = requests.get(cfg_url).text

sourceforge_cfg_url = os.environ("sf_cfg_url")
sourceforge_cfg = requests.get(sourceforge_cfg_url).text

def get_build():
  result = rclone.with_config(onedrive_cfg).run_cmd(command="link", extra_args=[f"Onedrive:Pixysos-test/{DEVICE}/{FOLDER}/{FILENAME}"])
  temp_link = result.get('out').decode("utf-8")
  fileid = temp_link.split("/")[4]
  link = f'http://seleniums.herokuapp.com/try/{fileid}/d'
  wget.download(link, f'{FILENAME}')
  
def buildapi:
def upload:
def telegram:
  
  
  
  
