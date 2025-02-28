#!/bin/bash

#############################################################################
#                                                                           #
# createProject.sh : Creates Project if does not exists                     #
#                                                                           #
#############################################################################

LOCAL_DEV_URL=$1
admin_user=$2
admin_password=$3
aliasName=$4
visibility=$5
description=$6
debug=${@: -1}

    if [ -z "$LOCAL_DEV_URL" ]; then
      echo "Missing template parameter LOCAL_DEV_URL"
      exit 1
    fi
    
    if [ -z "$admin_user" ]; then
      echo "Missing template parameter admin_user"
      exit 1
    fi

    if [ -z "$admin_password" ]; then
      echo "Missing template parameter admin_password"
      exit 1
    fi

    if [ -z "$aliasName" ]; then
      echo "Missing template parameter repoName"
      exit 1
    fi

    if [ -z "$visibility" ]; then
      echo "Missing template parameter repoName"
      exit 1
    fi

    if [ "$debug" == "debug" ]; then
      echo "......Running in Debug mode ......"
      set -x
    fi


function echod(){
  
  if [ "$debug" == "debug" ]; then
    echo $1
  fi

}



RUNTIME_REGISTER_URL=${LOCAL_DEV_URL}/apis/v1/rest/control-plane/runtimes/
 runtime_json='{ "name": "'${aliasName}'", "description": "'${description}'", "visibility": "'${visibility}'" }'

  echo "Registering Runtime"
  registerRuntimeJson=$(curl --location --request POST ${RUNTIME_REGISTER_URL} \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --data-raw "$runtime_json" -u ${admin_user}:${admin_password} -w ";-) %{http_code}")
  
  Status=$(echo $registerRuntimeJson | awk '{split($0,a,";-)"); print a[2]}')
  Body=$(echo $registerRuntimeJson | awk '{split($0,a,";-)"); print a[1]}')
  echod "Status:"$Status  
  echod "Body:"$Body  

if [ ${Status} -ge 200 ] && [ ${Status} -lt 300 ]; then
    name=$(echo "$Body" | jq -r '.name')
    agentID=$(echo "$Body" | jq -r '.agentID')
    echo "Registered "$name" with agentID "$agentID 
else
    message=$(echo "$Body" | jq -r '.integration.message.description')
    echo "Failed with Status Code: "$Status "and message: "$message
    exit 1
fi

RUNTIME_PAIR_URL=${LOCAL_DEV_URL}/apis/v1/rest/control-plane/runtimes/${aliasName}/instances/new-pairing-request

  echo "Pairing Runtime"
  pairRuntimeJson=$(curl --location --request POST ${RUNTIME_PAIR_URL} \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  -w ";-) %{http_code}")

    status=$(echo $pairRuntimeJson | awk '{split($0,a,";-)"); print a[2]}')
    body=$(echo $pairRuntimeJson | awk '{split($0,a,";-)"); print a[1]}')
    echod "Status:"$status  
    echod "Body:"$body  

if [ ${status} -ge 200 ] && [ ${Statustatuss} -lt 300 ]; then
    name=$(echo "$body" | jq -r '.agentName')
    agentID=$(echo "$body" | jq -r '.agentId')
    echo $body > ./${aliasName}_Paired.json
    echo "Paired "$agentName" with agentID "$agentID 
else
    message=$(echo "$body" | jq -r '.integration.message.description')
    echo "Failed with Status Code: "$status "and message: "$message
    exit 1
fi

