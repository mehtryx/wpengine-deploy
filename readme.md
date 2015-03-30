wpengine deploy
===============
> Because it would have taken twice as long to build it properly

Deployment script to handle multiple private repositories for themes and
plugins as Wpengine does not support sub-modules.

Requirements
------------
- Bash 4+

Installation requirements
-------------------------
1. Create path `/var/log/wpengine`
2. Create the following hierarchy:

	```
	~/deployments/
		├── plugins/
		├── themes/
		├── tmp/
		└── wpengine/
	```
3. Copy the `gitignore` file to `~/deployments/.gitignore`
4. Copy `wpengine.sh` script to `~/deployments` folder
5. Set permissions: `chmod 555 ~/deployments/wpengine.sh`
6. Symlink script for execution without extension: `ln -s ~/deployments/wpengine.sh`
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
	ln -s ~/path/to/project/wp-content/plugins deployments/plugins
	ln -s ~/path/to/project/wp-content/themes deployments/themes
	```

You should have the following listing within deployment:

	```bash
	lrwxr-xr-x  1 Justin  staff    68B Mar 27 12:29 plugins -> /path/to/project/wp-content/plugins
	lrwxr-xr-x  1 Justin  staff    67B Mar 27 12:29 themes -> /path/to/project/wp-content/themes
	drwxr-xr-x  4 Justin  staff   136B Mar 27 16:16 tmp
	drwxr-xr-x  3 Justin  staff   102B Mar 27 16:05 wpengine
	-rwxrwxrwx  1 Justin  staff   6.1K Mar 27 12:48 wpengine.sh
	```

9. Purge and clone initial wpengine repository into `deployments/wpengine/{repo/name}` via `wpengine.sh`
10. Run: `sudo wpengine staging|production` to begin deployment process

That is it, make sure to run the script normally without quiet mode to verify
everything works as expected.

Questions or problems, submit an issue to this repository, or submit a patch
request.
