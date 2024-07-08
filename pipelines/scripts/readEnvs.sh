#!/bin/bash

#############################################################################
#                                                                            #
# readEnvs.sh : read number of environments from the congig directory        #
#                                                                            #
#############################################################################

HOME_DIR=$1
CONFIG_DIR=$2
debug=${@: -1}

    if [ -z "$HOME_DIR" ]; then
      echo "Missing template parameter HOME_DIR"
      exit 1
    fi
    
    if [ -z "$CONFIG_DIR" ]; then
      echo "Missing template parameter CONFIG_DIR"
      exit 1
    fi

    if [ "$debug" == "debug" ]; then
      set -x
      echo "......Running in Debug mode ......"
    fi


function echod(){
  if [ "$debug" == "debug" ]; then
    echo $1 
  fi

}
declare -a envArr
i=0
envs=''
if [ -e $HOME_DIR/$CONFIG_DIR/*.yml ]; then
    for env in $HOME_DIR/$CONFIG_DIR/*.yml; do 
        echod $env
        base_name=${env##*/}
        parent_name="$(basename "$(dirname "$env")")"
        base_name=${base_name%.*}
        echod $base_name${env%.*}
        echod $parent_name
        envArr[i]=$(cat env | yq -e '.tenant.type // empty')
        let i++    
    done
    envs=$(IFS=$','; echo "${envArr[*]}")
    
    echod $envs
else
    echo "No environment file found"
    exit 1
fi   

echo envs

set +x


