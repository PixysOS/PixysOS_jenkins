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

function TG() {
   curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001322414571&parse_mode=Markdown" > /dev/null
}

function extras() {
   part1="\u003Ca href\u003D\x22"
   part2="\x22\u003E"
   part3="\u003C\u002Fa\u003E"
}

function build() {
   JSON=$(curl -s ${BJSON})
}
function post() {
   {
      echo -e "New PixysOS Update on $(date)"
      echo
      echo -e "⬇️ Download"
      echo -e "${part1}${url}${part2}${zip}${part3}"
      echo
      echo -e "   📱Device: Asus Zenphone Max Pro M1"
      echo -e "   ⚡️Build Version: v2.4"
      echo -e "   ⚡️MD5: 2dcb0417f96333cc1506cda7c6a43322"
      echo
      echo -e "By: ${part1}${url}${part2}${zip}${part3}"
      echo
      echo -e "Join👉 ${part1}${url}${part2}${zip}${part3} | ${part1}${url}${part2}${zip}${part3}"
   }
