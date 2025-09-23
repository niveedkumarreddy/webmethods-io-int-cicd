#!/bin/bash

####################################################################################################################################################################
#                                                                                                                                                                  #
#  deleteReferenceData.sh : Delete reference data entries from a webMethods.io Project                                                                             #
#                                                                                                                                                                  #
#  FUNCTIONS:                                                                                                                                                      #
#   - deleteReferenceData   : Deletes a single reference data entry by name.                                                                                       #
#   - extractReferenceData  : Batch-deletes reference data entries by reading them from a file (line by line).                                                     #
#                                                                                                                                                                  #
#  MANDATORY PARAMETERS:                                                                                                                                           #
#   LOCAL_DEV_URL           : Base URL of the Tenant (e.g., http://localhost:5555)                                                                                 #
#   admin_user              : Admin username for authentication                                                                                                    #
#   admin_password          : Admin password for authentication                                                                                                    #
#   referenceData           : The reference data name to delete (used in single delete)                                                                            #
#   repo_name               : Name of the project/repository where reference data exists                                                                           #
#   reference_data_file     : File containing a list of reference data names (one per line, used in batch delete)                                                  #
#                                                                                                                                                                  #
#  USAGE EXAMPLES:                                                                                                                                                 #
#   Delete a single reference data entry:                                                                                                                          #
#     ./deleteReferenceData.sh "http://localhost:5555" "admin" "password" "RefDataName" "MyRepo"                                                                   #
#                                                                                                                                                                  #
#   Delete multiple reference data entries from file:                                                                                                              #
#     ./deleteReferenceData.sh "http://localhost:5555" "admin" "password" "./referenceDataList.txt" "MyRepo"                                                       #
#                                                                                                                                                                  #
####################################################################################################################################################################


# Debug echo
function echod() {
  echo "[DEBUG] $@"
}

# Function to delete a single Reference Data entry
function deleteReferenceData() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  referenceData=$4
  repo_name=$5

  if [ -z "$referenceData" ]; then
    echo "❌ Reference data name not provided!"
    exit 1
  fi

  REFERENCEDATA_DELETE_URL="${LOCAL_DEV_URL}/apis/v1/rest/projects/${repo_name}/referencedata/${referenceData}"
  echod "Deleting reference data: $referenceData"
  echod "API URL: $REFERENCEDATA_DELETE_URL"

  response=$(curl --silent --location --request DELETE "$REFERENCEDATA_DELETE_URL" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    -u "${admin_user}:${admin_password}")

  status=$(echo "$response" | jq -r '.output.code // empty')

  if [ "$status" == "SUCCESS" ]; then
    echo "✅ Reference Data '$referenceData' deleted successfully."
  else
    echo "❌ Failed to delete reference data '$referenceData'"
    echo "Response: $response"
  fi
}

# Function to read reference data names from a file and delete them
function extractReferenceData() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  reference_data_file=$4
  repo_name=$5

  if [ ! -f "$reference_data_file" ]; then
    echo "❌ File not found: $reference_data_file"
    return 1
  fi

  echo "📄 Reading reference data names from file: $reference_data_file"
  while IFS= read -r referenceData || [ -n "$referenceData" ]; do
    # Skip empty lines or lines starting with #
    if [[ -n "$referenceData" && ! "$referenceData" =~ ^# ]]; then
      deleteReferenceData "$LOCAL_DEV_URL" "$admin_user" "$admin_password" "$referenceData" "$repo_name"
    fi
  done < "$reference_data_file"
}
