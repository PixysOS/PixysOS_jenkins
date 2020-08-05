#
# Copyright (C) 2020 PixysOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# PixysOS channel script.

import datetime, requests, json, os

from telegram import Bot
from telegram import InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Updater

bottoken = os.environ.get('bottoken')
BOT = Bot(token=bottoken)
UPDATER = Updater(bot=BOT, use_context=True)
TG_CHANNEL = "-1001325986623"

device = os.environ.get('DEVICE')
filename = os.environ.get('FILENAME')
if 'GAPPS' in filename:
  folder = 'ten_gapps'
  edition = 'GAPPS'
else:
  folder = 'ten'
  edition = 'NORMAL'

url = 'https://ota.pixysos.com/' + device + '/ten/' + folder + '.json'
build_json = json.loads(requests.get(url).text)
url = 'https://raw.githubusercontent.com/PixysOS/official_devices/ten/devices.json'
devices_json = json.loads(requests.get(url).text)
photo_url = 'https://raw.githubusercontent.com/PixysOS/Pixys_doc/android-10/Ban-Q.png'

for device_json in devices_json:
  if device_json["codename"] == device:
    codename = device
    device = device_json["name"]
    brand = device_json["brand"]
    maintainer = device_json["maintainer_name"]
    xda_thread = device_json["xda_thread"]
    version = build_json["response"][0]["version"]
    dts = str(datetime.datetime.fromtimestamp(int(build_json["response"][0]["datetime"])).strftime("%Y-%m-%d %H:%M"))
    url = build_json["response"][0]["url"]
    break

message = ''
message += '⚡PixysOS Update ⚡\n\n'
message += '➡️ New build available for (' + brand + ' ' + device + ') (' + codename + ')\n'
message += '👤 by ' + maintainer + '\n\n'
message += 'ℹ️ Version: ' + version + '\n'
message += '📆 Build date: (' + dts + ')\n'
message += '⚠️ Edition: ' + edition + '\n\n'
message += '<a href="' + url + '">⬇️ Download Now</a>\n'
if xda_thread:
  message += '<a href="' + xda_thread + '">💬 XDA Thread</a>'
message += '\n\n#PixysOS #' + codename

UPDATER.bot.send_photo(chat_id=TG_CHANNEL, caption=message, photo=photo_url, parse_mode='HTML', disable_web_page_preview='yes')
print(message)
