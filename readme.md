wpengine deploy
===============
> Because it would have taken twice as long to build it properly

Deployment script to handle multiple private repositories for themes and
plugins as wpengine does not support sub-modules.

Requirements
------------
- Bash 4+

Installation requirements
-------------------------
1. Create path `/var/log/wpengine`
2. Create the following hierarchy:

	```
	/deployments/
		├── plugins/
		├── themes/
		├── tmp/
		└── wpengine/
	```
3. Copy the `gitignore` file to `/deployments/.gitignore`
4. Copy `wpengine.sh` script to `/deployments` folder
5. Set permissions: `chmod 555 /deployments/wpengine.sh`
6. Symlink script for execution without extension: `ln -s /deployments/wpengine.sh wpengine`
7. Modyify the repos array with the descriptions and match up corresponding targets:

	```
	# be sure to set the value to the same target per line, make sure all entries in this array are lowercase
	declare -A targets=(    ["staging"]="staging"   ["s"]="staging"
	                        ["p"]="production"      ["prod"]="production"
							["production"]="production"
							)
	# be sure the repo matches the target values above, you need one repo entry per unique target value
	declare -A repos=(      ["staging"]="git@git.wpengine.com:staging/roadkill.git"
							["production"]="git@git.wpengine.com:production/roadkill.git"
							)
	```

8. Symlink all required themes and plugins with local path:

	```
	ln -s ~/path/to/project/wp-content/plugins /deployments/plugins
	ln -s ~/path/to/project/wp-content/themes /deployments/themes
	```

9. Run: `sudo wpengine staging|production` to begin deployment process

10. Please purge and clone the wpengine repo on initial start to grab the latest
	wpengine instance

That is it, make sure to run the script normally without quiet mode to verify
everything works as expected.

Questions or problems, submit an issue to this repository, or submit a patch
request.
