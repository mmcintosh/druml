#!/bin/bash

# Get Druml dir.
SCRIPT_DIR=$1
shift

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 1 || -z $PARAM_SITE || -n $PARAM_HELP ]]
then
  echo "usage: druml local-sitesync [--config=<path>] [--docroot=<path>]"
  echo "                            [--jobs=<number>] [--delay=<seconds>]"
  echo "                            --site=<subsite> | --list=<list>"
  echo "                            [--server=<number>]"
  echo "                            <environment>"
  exit 1
fi

# Read parameters.
SUBSITE=$(get_site_alias $PARAM_SITE)
ENV=$(get_environment ${ARG[1]})

# Set variables.
DRUSH_SUBSITE_ARGS=$(get_drush_subsite_args $SUBSITE)
SUBSITE_FILES="$(get_docroot)/sites/$SUBSITE/files"
PROXY_PARAM_SERVER=$(get_param_proxy "server")

# Say hello.
echo "=== Sync '$SUBSITE' subsite from the '$ENV' environment to the localhost"
echo "You may be pormted to enter a sudo password."
echo ""

# Prepare files dir.
echo "=== Prepare files directory"
if [ -d $SUBSITE_FILES ];
then
  sudo rm -rf $SUBSITE_FILES
fi
mkdir $SUBSITE_FILES
mkdir $SUBSITE_FILES/private
chmod -R a+rwx  $SUBSITE_FILES
echo "Done!"
echo ""

# Sync db.
run_script "local-dbsync" --site=$SUBSITE $PROXY_PARAM_SERVER $ENV

echo "=== Prepare website for local development"
# Enable dev modules.
if [ -n $CONF_LOCAL_SYNC_ENABLE ]
then
  drush -r $(get_docroot) $DRUSH_SUBSITE_ARGS en $CONF_LOCAL_SYNC_ENABLE -y
fi

# Disable prod modules.
if [ -n $CONF_LOCAL_SYNC_DISABLE ]
then
  drush -r $(get_docroot) $DRUSH_SUBSITE_ARGS dis $CONF_LOCAL_SYNC_DISABLE -y
fi

# Clear cache.
drush -r $(get_docroot) $DRUSH_SUBSITE_ARGS cc all

# Resave theme settings.
drush -r $(get_docroot) $DRUSH_SUBSITE_ARGS php-eval "#
    module_load_include('inc', 'system', 'system.admin');
    foreach (array('at_georgetown') as \$theme_name) {
      \$form_state = form_state_defaults();
      \$form_state['build_info']['args'][0] = \$theme_name;
      \$form_state['values'] = array();
      drupal_form_submit('system_theme_settings', \$form_state);
    }
"

# Get login URL.
drush -r $(get_docroot) $DRUSH_SUBSITE_ARGS uli
sudo chmod -R a+rwx $SUBSITE_FILES
echo "Complete!"
echo ""
