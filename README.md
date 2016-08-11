DESCRIPTION
=====

*Druml* is a Drupal multisite tool that helps to maintain multiple Drupal sites. It has been developed in Georgetown University, which maintains over 250 Drupal websites.

*Druml* is a set of bash scripts. Despite the *Druml* sounds similar to *Drush*, it is not a replacement to *Drush*, instead it is an addition to *Drush* and it uses *Drush* a lot. It also works nice with *Acquia Cloud Platform* and there are some specific *Acquia Cloud* commands.

Interesting thing about *Druml* is that it does not require you to have *Drush* installed on your local machine, though it should be installed on the remote server.

FEATURES
-----
* Provides over 15 useful command wrappers for Drush, Bash, Memcache, SAML, Acquia Cloud.
* Allows to run any existing Drush commands chained in a batch.
* Runs commands either for multiple sites or individually.
* Allows to manage list of different sites and control execution priority.
* Allows to run commands in parallel threads.
* Could be extended with custom commands.
* Reads configuration from Yaml file.
* Installed easily.

ALTERNATIVES
-----

There are several alternatives to *Druml*, but they are not powerful as it is.

* `drush @sites` - nice and dirty workaround, though very limited.
* [Automatic Drush Aliases](http://dropbucket.org/node/749) - interesting approach but limited to Drush commands only, does not allow to run multiple commands in a chain or run them in parallel.

INSTALLATION
-----

Perform following code in the terminal:

  ```
  cd ~
  wget -qO- https://github.com/georgetown-university/druml/archive/master.zip | tar xvz && mv druml-master druml
  ln -s ~/druml/druml.sh /usr/local/bin/druml
  ```

EXAMPLES
-----

Here are some example of how you can use *Druml* in your deployment and development workflows.

* Performs multiple Drush commands for all sites running in 3 parallel jobs on production server.
  ```
  druml remote-drush prod --list=all --jobs=3 "rr" "updb -y" "fra -y" "cc all"
  ```

* Calculates amount of nodes for each site on prod, output result as a CSV file.
  ```
  druml remote-php prod --list=all --source=php/node-count.php --output=res/node-count.csv
  ```

* Copies DB and files of edited sites from stage environment to production in *Acuia Cloud*. This command also makes DB backup prior and flushes Memcache and Drupal cache after then execution.
  ```
  druml remote-ac-sitesync --list=edited stg prod
  ```
  
* Copies DB and files from a remote server to a local environment. This command also enabled development modules specified in the configuration.
  ```
  druml local-sitesync --site=mysite prod
  ```

AVAILABLE COMMANDS
-----
```
  local-listupdate         Updates a list file that contains subsites
  local-dbsync             Syncs a subsite DB from a remote env to a local one
  local-samlsign           Signes SAML metadata file
  local-sitesync           Syncs a subsite (DB and files) from a remote env to a
                           local one
  remote-ac-codedeploy     Deploys code from one environment to another
  remote-ac-codepathdeploy Deployes a tag/branch to the specific enviornment
  remote-ac-command        Executes any drush ac command
  remote-ac-dbbackup       Backup a DB
  remote-ac-dbsync         Syncs a subsite DB from one env to another
  remote-ac-sitesync       Syncs a subsite (DB and fies) from one env to another
  remote-ac-status         Waits until the task is completed
  remote-ac-tagget         Returns tag or branch associated with environment
  remote-bash              Performs arbitrary bash commands for a specific env
  remote-drush             Performs arbitrary drush commands for a specific subsite
  remote-filesync          Syncs subsite fies from one env to another
  remote-memcacheflush     Syncs subsite fies from one env to another
  remote-php               Performs a php code for a specific subsite
```
Check druml --help or druml <command> --help for more info.


LISTS
-----

Lists is a powerfull instrument in *Druml* that allows to run commands for multiple sites. Here is what you can do.

* To run a command for a list of sites use `--list` parameter.
  ```
  druml <command> --list=<listname> <arguments>
  ```

* To decrease a load on a server while commands are being executed you can set delays between iterations. This can be done with a help of `--delay` parameter.
  ```
  druml <command> --delay=<seconds> --list=<listname> <arguments>
  ```

* To run commands for multiple sites in parallel threads use `--jobs` parameter.
  ```
  druml <command> --jobs=<number> --list=<listname> <arguments>
  ```
  
To perform a command for multiple sites you need to have subsites grouped in a list file. Subsites are typically folder names in `sites/all` directory of a Drupal site. List file is a simple text file, which contains subsites separated by the new line character, e.g.:
```
default
clone_a
clone_z
```

To generate a list of all sites based on your *Drupal* installation run `local-listupdate` command.
```
druml local-listupdate --docroot=<path to drupal> --list=<listname>
```

You also need to define list files in the Druml configuration file, e.g.:
```
list:
  all: list/all.txt
  vip: list/vip.txt
  test: list/test.txt
```

See [Configuration](#CONFIGURATION) section for more information.

CONFIGURATION
-----
Before using Druml you need to have a configuration file, see [example.druml.yml](https://github.com/georgetown-university/druml/blob/master/example.druml.yml) as an example of it.

By default *Druml* loads configuration which is sotred in the `druml.yml` localted in the current directory. When running *Druml* you can also specify path to the configuration file using `--config` parameter.
```
druml --config=~/supersite.yml <command> <arguments>
```

CUSTOM COMMANDS
-----
*Druml* allows you to define custom commands and utilize it's internal power. To define a custom command create command file in the same directory as configuration file. File should be in the following format `druml-custom-<commandname>.sh`. Make sure it is executable: `chmod a+x druml-custom-<commandname>.sh`

Here is an example of custom command that we use in *Georgetown* to create a new site.
```
#!/bin/bash

# Exit upon first error
set -e

# Make sure results are outputted immideately.
exec 1> /dev/tty
exec 2> /dev/tty

# Get Druml dir.
SCRIPT_DIR=$1
shift

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 1 || -z $PARAM_SITE || -n $PARAM_HELP ]]
then
  echo "usage: druml custom-siteprovision [--config=<path>] --site=<subsite>"
  echo "                                  [--domain=<domain>]"
  echo "                                  <site name> <install profile>"
  exit 1
fi

# Read parameters.
SITE=$PARAM_SITE
if [[ ! -z $PARAM_DOMAIN ]]; then
  PRODDOMAIN=$PARAM_DOMAIN
else
  PRODDOMAIN="$SITE.georgetown.edu"
fi
ENV=$(get_environment ${ARG[1]})
NAME=${ARG[1]}
PROFILE=${ARG[2]}

run_script custom-sitecreate --site=$SITE --domain=$PRODDOMAIN prod
run_script custom-siteinstall --site=$SITE prod "$NAME" $PROFILE
run_script remote-ac-sitesync --site=$SITE prod test
run_script remote-ac-sitesync --site=$SITE prod dev
run_script remote-drush --site=$CONF_CUSTOM_DEFAULTSITE prod "ac-domain-purge gudrupal.prod.acquia-sites.com"
```

CONTRIBUTE!
-----
This project is in active development, if you have any ideas or want to submit a bug, plese, check [issues](https://github.com/georgetown-university/druml/issues).
