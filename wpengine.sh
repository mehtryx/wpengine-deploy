#!/bin/bash
# If any commands fail (exit code other than 0) entire script exits
set -e

#
# Installation requirements:
#
#  1. Create path /var/log/wpengine for the logging
#  2. Create the following hierarchy, or modify the script for deployment files:
#		 /deployments
#			 |---- tmp
#			 |---- themes
#			 |---- plugins
#			 |---- wpengine
#  3. Copy the gitignore file to /deployments/.gitignore
#  4. Copy wpnegine.sh to /deployments
#  5. Set permissions on script: chmod 555 /deployments/wpengine.sh
#  6. Symlink script for execution without extension:  ln -s /deployments/wpengine.sh /usr/local/bin/wpengine
#  7. Modify the repos array with the descriptions and *MATCH* up corresponging targets in the targets array. 
#  8. Symlink all required themes and plugins with local path
#  9. Run sudo wpengine staging|production to being deployment process
# 10. Please purge and clone wpengine repo on initial start to grab the latest wpengine instance
#
# That is it, make sure to run the script normally without quiet mode to verify everything works as expected.
#

# be sure to set the value to the same target per line, make sure all entries in this array are lowercase
declare -A targets=(    ["staging"]="staging"   ["s"]="staging"
                        ["p"]="production"      ["prod"]="production"   ["production"]="production"
)
# be sure the repo matches the target values above, you need one repo entry per unique target value
declare -A repos=(      ["staging"]="git@git.wpengine.com:staging/postmedia.git"
                        ["production"]="git@git.wpengine.com:production/postmedia.git"
)

LOGFILE=/var/log/wpengine/deployment.log
DATE="$(date +%Y%m%d-%H%M%S)"
user=`whoami`
server=`uname -n`
target=""
quiet=false
skipped=false

cwd=$(pwd)
# Warning, we will be using rm with this variable, we are going to check and prevent usage on root
if [ -d "$cwd" ];
then
	# This is a valid directory, so lets make sure its not root
	if [ "$(stat -s /)" == "$(stat -s $cwd)" ];
	then
		echo "Error: Script executing from root, or pwd returned root path."
		exit 1
	fi
else
	echo "Error: Script path provided by pwd is not a valid directory path."
	exit 1
fi

log () {
       message="$(date +%Y-%m-%d) $(date +%H:%M:%S) - $user [INFO] - $@"
       echo $message
       echo $message >>$LOGFILE
}

# Store the last commit message in the log, makes it easier to see what commits were deployed when.
logcommit() {
	message="$(date +%Y-%m-%d) $(date +%H:%M:%S) - $user [INFO] - Last commit (git log -1)"
	echo $message >> $LOGFILE
        echo -e `git log -1` >> $LOGFILE
}

usage () {
		echo
		echo "usage: ./wpengine.sh [environment] [-q|--quiet]"
		echo
		echo "    Possible environment values: staging, prod"
		echo "    -q --quite prevents confirmation prompts"
		echo
		kill -SIGINT $$ # Ends script
}

proceed () {
	if ! $quiet;
	then
		skipped=false # reset global var
		prompt="$@"
		yno=false
		while ! $yno; do
			echo
			echo -n "$prompt: "
			read yno
			case $yno in
				[yY] | [yY][eE][sS] )
					skipped=false
					yno=true
					;;
				[nN] | [nN][oO] )
					skipped=true
					yno=true
					;;
				* )
					yno=false
					echo "Invalid response, please try again."
					;;
			esac
		done
	fi
}

failout() {
	log $@
	kill -SIGINT $$ # Ends script
}

gitpull() {
	cd $@ # change to the git repository to pull from, passed as a parameter
	if [ "$?" == "0" ] ; then
		git pull
		if [ "$?" != "0" ] ; then
			failout "Unable to pull for gitrepo at $@"
		fi
	else
		failout "Path not found $@"
	fi
}

environment () {
	for target_entry in "${!targets[@]}"
	do
		if [ "$param" == "$target_entry" ]
		then
			env="${targets[$param]}"
		fi
	done

	if [[ -z "$env" ]];
	then
		case "$param" in 
			-q | --quiet )
				quiet=true
				;;
			* )
				usage
				;;
		esac
	fi
	target="$env"
}

# check first parameter
if [[ -z "$1" ]]
then
	usage # no parameters sent, show usage and exit
fi
param=$1
environment

# check for second parameter
if [[ -z "$2" ]]
then
	if [[ -z "$target" ]]
	then
		usage # missing target, and no second paramater, show usage and exit
	fi
else
	param=$2 # check second parameter and flag quiet
	environment
	if [[ -z "$target" ]] 
	then
		usage # We've tested the second parameter and still have no target...show usage and exit
	fi
fi

# Script now proceeds based on the settings passed above

log "=========================================================================================="
if $quiet; 
then
	log "Executing in quiet mode, no confirmation prompts will be displayed..."
fi
log "Deployment to wpengine $target..."

# clear the tmp folder
rm -rf $cwd/tmp/*

# Option to purge repo, if not in quiet mode...this is useful if you think your local repo is out of sync and will cause merge conflicts.
if ! $quiet; then
	proceed "Purge and clone new instance of wpengine $target?"
	if ! $skipped; then
		log "Purging wpengine folder and cloning ${repos[$target]} to wpengine/$target" 
		rm -rf $cwd/wpengine/$target
		git clone ${repos[$target]} $cwd/wpengine/$target
		if [ "$?" != "0" ] ; then
			failout "Unable to clone ${repos[$target]}"
		fi
	else
		log "Pulling changes from ${repos[$target]}"
		gitpull $cwd/wpengine/$target

	fi
fi

# copy in our custom gitignore file
cp .gitignore $cwd/wpengine/$target/

echo
log "Syncing themes...."
for theme in `ls $cwd/themes/`; do
	if ! $quiet; then
		proceed "Pull changes from $theme?"
	fi
	if ! $skipped; then
		log "Pulling changes from $theme...."
		gitpull $cwd/themes/$theme
		logcommit
	fi
done

echo
log "Syncing plugins...."
for plugin in `ls $cwd/plugins/`; do
	if ! $quiet; then
		proceed "Pull changes from $plugin?"
	fi
	if ! $skipped; then
		log "Pulling changes from $plugin...."
		gitpull $cwd/plugins/$plugin
		logcommit
	fi
done

echo
log "Transfering files to tmp for inclusion to wpengine..."
cp -rp $cwd/themes $cwd/tmp/
cp -rp $cwd/plugins $cwd/tmp/

echo
log "Removing git folders (if present) from tmp..."
find $cwd/tmp/ -type d -name .git -exec rm -rf {} \;

echo
log "Moving cleaned repos into wpengine repository..."
cp -r $cwd/tmp/* $cwd/wpengine/$target/wp-content/

echo
log "Displaying status of wpengine git repo..."
cd $cwd/wpengine/$target
git status

echo
if ! $quiet; then
	proceed "Proceed with deployment to wpengine $target?"
fi
if ! $skipped; then
	log "Adding/committing changes to wpengine git...."
	git add .
	git commit -am "Deployment to $target wpengine by $user from $server"

	echo -n "pushing to wpengine $target..."
	echo
	git push origin master
	echo
else
	log "deployment aborted by user..."
	# removes all file changes so we do not keep any from past copy operations.
	git add . && git reset --hard HEAD
fi
log "completed."
