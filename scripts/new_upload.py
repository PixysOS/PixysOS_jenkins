import json, wget, requests, rclone
from os import environ
from pathlib import Path

# Onedrive config
onedrive_cfg_url = environ.get("onedrive_cfg_url")
onedrive_cfg = requests.get(onedrive_cfg_url).text

# Sourceforge config
sourceforge_cfg_url = environ.get("sf_cfg_url")
sourceforge_cfg = requests.get(sourceforge_cfg_url).text

# Needed build parameters
DEVICE = environ.get("DEVICE")
FOLDER = environ.get("FOLDER")
FILENAME = environ.get("FILENAME")

def get_build():
  # Get the download link of the file
  result = rclone.with_config(onedrive_cfg).run_cmd(command="link", extra_args=[f"Onedrive:Pixysos-test/{DEVICE}/{FOLDER}/{FILENAME}"])
  # Create the download link
  if (result.get('error') != 0):
    print(f"{FILENAME} is not existing in test folder")
    exit(1)
  # As the indirect link is generated means the file exits on the server so get the fileid to process further
  fileid = result.get('out').decode("utf-8").split("/")[4]
  link = f'http://seleniums.herokuapp.com/try/{fileid}/d'
  # Download the file
  wget.download(link, f'{FILENAME}')
  # To check if the file was downloaded or not
  if Path(f'{FILENAME}').is_file():
    print ("File downloaded properly now uploading!")
    buildapi()
    upload()
  else:
    print ("File not downloaded properly")
    exit(1)
  
def buildapi:
def upload():
  result = rclone.with_config(onedrive_cfg).run_cmd(command="copy", extra_args=[f"{FILENAME}", f"Onedrive:PixysOS/{DEVICE}/{FOLDER}"])
  if (result.get('error') != 0):
    print("Upload task failed")
    exit(1)
  result = rclone.with_config(sourceforge_cfg).run_cmd(command="copy", extra_args=[f"{FILENAME}", f"Sourceforge:PixysOS/{DEVICE}"])
  if (result.get('error') != 0):
    print("Upload task failed")
    exit(1)
  
  
  
