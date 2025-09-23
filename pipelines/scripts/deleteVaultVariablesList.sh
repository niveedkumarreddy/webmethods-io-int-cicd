#!/bin/bash

####################################################################################################################################################################
#                                                                                                                                                                  #
#  deleteVaultVariable.sh : Delete one or more Vault Variables from webMethods.io Tenant                                                                           #
#                                                                                                                                                                  #
#  FUNCTIONS:                                                                                                                                                      #
#   - deleteVaultVariable        : Deletes a single vault variable by name.                                                                                        #
#   - extractDeleteVaultVariables: Reads variable names from a file and deletes them in batch.                                                                     #
#                                                                                                                                                                  #
#  MANDATORY PARAMETERS:                                                                                                                                           #
#   LOCAL_DEV_URL                : Base URL of the Tenant (e.g., http://localhost:5555)                                                                            #
#   admin_user                   : Admin username for authentication                                                                                               #
#   admin_password               : Admin password for authentication                                                                                               #
#   variable_name                : Vault variable name to delete (used in single delete)                                                                           #
#   extract_keys_file            : File containing list of vault variable names (one per line, used for batch delete)                                              #
#                                                                                                                                                                  #
#  USAGE EXAMPLES:                                                                                                                                                 #
#   Delete a single Vault Variable:                                                                                                                                #
#     ./deleteVaultVariable.sh "http://localhost:5555" "admin" "password" "MyVariable"                                                                             #
#                                                                                                                                                                  #
#   Delete multiple Vault Variables from a file:                                                                                                                   #
#     ./deleteVaultVariable.sh "http://localhost:5555" "admin" "password" "./variablesList.txt"                                                                    #
#                                                                                                                                                                  #
####################################################################################################################################################################


# Debug echo
function echod() {
  echo "[DEBUG] $@"
}

# Function to delete a vault variable
function deleteVaultVariable() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  variable_name=$4

  if [ -z "$variable_name" ]; then
    echo "❌ Variable name not provided!"
    exit 1
  fi

  VAULT_VARIABLES_DELETE_URL="${LOCAL_DEV_URL}/apis/v2/rest/configurations/variables/${variable_name}"
  echod "Deleting variable: $variable_name"
  echod "API URL: $VAULT_VARIABLES_DELETE_URL"

  response=$(curl --silent --location --request DELETE "$VAULT_VARIABLES_DELETE_URL" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    -u "${admin_user}:${admin_password}")

  status=$(echo "$response" | jq -r '.output.code // empty')

  if [ "$status" == "SUCCESS" ]; then
    echo "✅ Vault Variable '$variable_name' deleted successfully."
  else
    echo "❌ Failed to delete Vault Variable '$variable_name'"
    echo "Response: $response"
  fi
}

# Function to extract variable names from a file and delete them
function extractDeleteVaultVariables() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  extract_keys_file=$4

  if [ ! -f "$extract_keys_file" ]; then
    echo "❌ File not found: $extract_keys_file"
    return 1
  fi

  echo "📄 Reading variables from file: $extract_keys_file"
  while IFS= read -r variable_name || [ -n "$variable_name" ]; do
    # Skip empty lines or commented lines
    if [[ -n "$variable_name" && ! "$variable_name" =~ ^# ]]; then
      deleteVaultVariable "$LOCAL_DEV_URL" "$admin_user" "$admin_password" "$variable_name"
    fi
  done < "$extract_keys_file"
}

