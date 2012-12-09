#!/bin/sh

basedir="/srv/backup"
includefile="include.inc"
excludefile="exclude.inc"
backuphost="remote.backup.com"
retention="7"

timestamp=`date "+%Y-%m-%d_%H:%M:%S"`

# ensure our target directory exists
ssh $backuphost "mkdir -p $basedir/$(hostname -f)"

# loop through all the include dirs
for source in $(cat $includefile); do
	# perform the rsync
	rsync -azP --delete --delete-excluded --link-dest=$basedir/$(hostname -f)/current --exclude-from=$excludefile $source $backuphost:$basedir/$(hostname -f)/$timestamp
done

# create the symlink to the 'current' directory
ssh $backuphost "rm -f $basedir/$(hostname -f)/current && ln -s $timestamp $basedir/$(hostname -f)/current"

# check for and remove old backups
numbackups="$(ssh $backuphost "ls $basedir/$(hostname -f)/ | grep -v current | wc -l")"
if [ "$numbackups" -gt "$retention" ]; then
	for targetdir in $(ssh $backuphost "ls $basedir/$(hostname -f)/ | head -n $(($numbackups-$retention))"); do
		ssh $backuphost "rm -rf $basedir/$(hostname -f)/$targetdir"
	done
fi
