#!/bin/sh

# Save script dir.
SCRIPT_DIR=$(cd $(dirname "$0") && pwd -P)

# Load includes.
source $SCRIPT_DIR/dmul-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 2 || -n $PARAM_HELP ]]
then
  echo "usage: dmul remote-bash [--config=<path>] <environment> <commands>"
  echo ""
  echo "You can use following variables in a command:"
  echo " @DOCROOT - subsite docroot"
  echo " @LOG     - logs dir"
  exit 1
fi

# Load config.
source $SCRIPT_DIR/dmul-inc-config.sh

# Read parameters.
ENV=$(get_environment ${ARG[1]})
SSH_ARGS=$(get_ssh_args $ENV)
DRUSH_ALIAS=$(get_drush_alias $ENV)

# Read variables and form commands to execute.
echo "=== Execute bash commands on the $ENV environment"
echo "Commands to be executed:"

# Read commands.
COMMANDS=""
I=1
for CMD in ${ARG[@]}
do
  if [[ $I -gt 1 && -n ${ARG[$I]} ]]
  then
    COMMANDS="$COMMANDS ${ARG[$I]};"
  fi
  I=$((I+1))
done

# Replace variables.
COMMANDS=${COMMANDS/@DOCROOT/$(get_remote_docroot $ENV)}
COMMANDS=${COMMANDS/@LOG/$(get_remote_log $ENV)}

# Output commands.
echo $COMMANDS
echo ""

# Execute bash commands
ssh -tn $SSH_ARGS "$COMMANDS"

echo ""
echo "Complete!"
echo ""