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
  fi


function echod(){
  
  if [ "$debug" == "debug" ]; then
    echo $1
  fi

}



RUNTIME_REGISTER_URL=${LOCAL_DEV_URL}/apis/v1/rest/control-plane/runtimes/
 runtime_json='{ "name": "'${aliasName}'", "description": "'${description}'", "visibility": "'${visibility}'" }'


  echo "Registering Runtime"
  registerRuntimeJson=$(curl  --location --request POST ${RUNTIME_REGISTER_URL} \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --data-raw "$runtime_json" -u ${admin_user}:${admin_password} -w "%{stderr}{\"status\": \"%{http_code}\", \"body\":\"%{stdout}\"}" ) 

  echo $registerRuntimeJson
  #outputArray=(${registerRuntimeJson//;/ })
  http_response=$(echo "$registerRuntimeJson" | jq -r '.status')
  registerRuntimeJson=$(echo "$registerRuntimeJson" | jq -r '.body')
  echo "ResponseCode "$http_response
  echo "Output "$registerRuntimeJson



  name=$(echo "$registerRuntimeJson" | jq -r '.name')
  agentID=$(echo "$registerRuntimeJson" | jq -r '.agentID')


  echo "Registered "$name" with agentID "$agentID 







