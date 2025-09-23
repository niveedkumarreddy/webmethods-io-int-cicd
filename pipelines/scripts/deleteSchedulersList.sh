#!/bin/bash


####################################################################################################################################################################
#                                                                                                                                                                  #
#  deleteScheduler.sh : Delete one or more schedulers from a webMethods.io Project                                                                                 #
#                                                                                                                                                                  #
#  FUNCTIONS:                                                                                                                                                      #
#   - deleteScheduler        : Deletes a single scheduler by flow service name.                                                                                    #
#   - extractDeleteSchedulers: Reads scheduler names from a file and deletes them in batch.                                                                        #
#                                                                                                                                                                  #
#  MANDATORY PARAMETERS:                                                                                                                                           #
#   LOCAL_DEV_URL            : Base URL of the Tenant (e.g., http://localhost:5555)                                                                                #
#   admin_user               : Admin username for authentication                                                                                                   #
#   admin_password           : Admin password for authentication                                                                                                   #
#   flowServiceName          : Flow service name tied to the scheduler (used in single delete)                                                                     #
#   repo_name                : Name of the project/repository                                                                                                      #
#   scheduler_file           : File containing scheduler names (one per line, used for batch delete)                                                               #
#                                                                                                                                                                  #
#  USAGE EXAMPLES:                                                                                                                                                 #
#   Delete a single scheduler:                                                                                                                                     #
#     ./deleteScheduler.sh "http://localhost:5555" "admin" "password" "flowServiceName1" "MyRepo"                                                                  #
#                                                                                                                                                                  #
#   Delete multiple schedulers from a file:                                                                                                                        #
#     ./deleteScheduler.sh "http://localhost:5555" "admin" "password" "./schedulerList.txt" "MyRepo"                                                               #
#                                                                                                                                                                  #
####################################################################################################################################################################



# Debug echo
function echod() {
  echo "[DEBUG] $@"
}

# Function to delete a scheduler
function deleteScheduler() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  flowServiceName=$4
  repo_name=$5

  if [ -z "$flowServiceName" ]; then
    echo "❌ flowServiceName not provided!"
    exit 1
  fi

  SCHEDULER_DELETE_URL="${LOCAL_DEV_URL}/apis/v1/rest/projects/${repo_name}/configurations/schedulers/${flowServiceName}"
  echod "Deleting scheduler: $flowServiceName"
  echod "API URL: $SCHEDULER_DELETE_URL"

  response=$(curl --silent --location --request DELETE "$SCHEDULER_DELETE_URL" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    -u "${admin_user}:${admin_password}")

  status=$(echo "$response" | jq -r '.output.code // empty')

  if [ "$status" == "SUCCESS" ]; then
    echo "✅ Scheduler '$flowServiceName' deleted successfully."
  else
    echo "❌ Failed to delete scheduler '$flowServiceName'"
    echo "Response: $response"
  fi
}

# Function to extract scheduler names from file and delete them
function extractDeleteSchedulers() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  scheduler_file=$4
  repo_name=$5

  if [ ! -f "$scheduler_file" ]; then
    echo "❌ File not found: $scheduler_file"
    return 1
  fi

  echo "📄 Reading scheduler names from file: $scheduler_file"
  while IFS= read -r serviceName || [ -n "$serviceName" ]; do
    # Skip empty lines or commented lines
    if [[ -n "$serviceName" && ! "$serviceName" =~ ^# ]]; then
      deleteScheduler "$LOCAL_DEV_URL" "$admin_user" "$admin_password" "$serviceName" "$repo_name"
    fi
  done < "$scheduler_file"
}
