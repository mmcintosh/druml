#!/bin/bash

# Save script dir.
SCRIPT_DIR=$(cd $(dirname "$0") && pwd -P)

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 1 || -z $PARAM_SITE || -n $PARAM_HELP ]]
then
  echo "usage: druml local-dbbackup [--config=<path>] [--delay=<seconds>]"
  echo "                            [--site=<subsite> | --list=<list>]"
  echo "                            <environment>"
  exit 1
fi

# Load config.
source $SCRIPT_DIR/druml-inc-config.sh

# Read parameters.
SUBSITE=$PARAM_SITE
ENV=$(get_environment ${ARG[1]})
DRUSH=$(get_drush_command)
DRUSH_ALIAS=$(get_drush_alias $ENV)
SSH_ARGS=$(get_ssh_args $ENV)
DRUSH_SUBSITE_ARGS=$(get_drush_subsite_args $SUBSITE)

# Say Hello.
echo "=== Backup '$SUBSITE' DB at the $ENV"
echo ""

OUTPUT=$(ssh -Tn $SSH_ARGS "$DRUSH $DRUSH_ALIAS $DRUSH_SUBSITE_ARGS ac-database-instance-backup $SUBSITE" 2>&1)
RESULT="$?"
TASK=$(echo $OUTPUT | awk '{print $2}')

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  echo "Error syncing DB."
  exit 1
fi
echo "$OUTPUT"
echo "Database backup scheduled."

# Check task status.
OUTPUT=$(run_script remote-ac-status $ENV $TASK 2>&1)
RESULT="$?"
echo "$OUTPUT"
if [[ $RESULT > 0 ]]; then
  echo "Database backup failed!"
  exit 1
fi

echo "Database backup completed!"