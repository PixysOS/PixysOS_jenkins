#!/usr/bin/env bash

# A gerrit script to push all repositories from a manifest

# This again, will have to be adapted based on your setup.

cwd=$PWD
cd ~/pixys
PROJECTS="$(grep 'pixys' .repo/manifests/snippets/pixys.xml  | awk '{print $2}' | awk -F'"' '{print $2}' | uniq | grep -v caf)"
for project in ${PROJECTS}
do
    cd $project
    echo $project
    git push -o skip-validation $(git remote -v | head -1 | awk '{print $2}' | sed -e 's/https:\/\/github.com\/PixysOS/ssh:\/\/Subinsmani@gerrit.pixysos.com:29418\/PixysOS/') HEAD:refs/heads/ten
    cd -
done
cd $cwd
