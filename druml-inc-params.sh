# Parse script parameters and arguments.
I=1
while test ${#} -gt 0
do  
  _P_NAME=$(get_parameter_name $1)
  _P_NAME_U=$(echo $_P_NAME | tr '[:lower:]' '[:upper:]')
  _P_VALUE=$(get_parameter_value $1)

  if [[ -n $_P_NAME ]]
  then
    PROXY_PARAMS="$PROXY_PARAMS --$_P_NAME='$_P_VALUE'";

    if [[ -z $_P_VALUE ]]
    then
      _P_VALUE=_P_NAME_U
    fi
    _PARAM_NAME="PARAM_${_P_NAME_U}"
    eval $_PARAM_NAME=$_P_VALUE
  else
    ARG[$I]=$1;
    if [[ $I>1 || `basename $0` != "druml.sh" ]]
    then
      PROXY_ARGS="$PROXY_ARGS '$1'"
    fi
    I=$I+1
  fi

  shift
done