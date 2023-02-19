#!/bin/bash
#
# Fix externals conversion to symbolic link after upgrading the GitHub Actions agent.
#
# This addresses Podman being unable to mount that externals directory as a symlink.
# This cron task will run every 5 min to check if 'externals' has become a symlink
# 15 min prior to the current time. If thats the case, the symlink will be removed
# and the symlink target will be moved to the 'externals' path.

readarray -t GHA_UNITS < <(systemctl list-units actions.runner* --all -q | cut -d ' ' -f 3)
declare p GHA_UNITS

for i in "${GHA_UNITS[@]}"
do
  working_dir=$(cat $(systemctl show -P FragmentPath $i) | grep ExecStart | cut -f 2 -d '=' | head -n 1 | xargs dirname)
  if [[ -L "$working_dir/externals" && -d "$working_dir/externals" ]]
  then
    echo "$working_dir/externals is a symlink to a directory"
    externals_target=$(readlink -f "$working_dir/externals")
    if [[ $(date --date="-15 minutes" +%s) > $(date -r "$working_dir/externals" +%s) ]]
    then
      echo "Removing symbolic link and moving the directory"
      rm -f "$working_dir/externals"
      mv "$externals_target" "$working_dir/externals"
    fi
  fi
done
