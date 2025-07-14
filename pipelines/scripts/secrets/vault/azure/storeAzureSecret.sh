#!/bin/bash

#############################################################################
#                                                                           #
# storeAzureSecret.sh : Stores a secret in Azure Key Vault                  #
#                                                                           #
#############################################################################

# ============ INPUT PARAMETERS ============
VAULT_NAME=$1      # Key Vault name
SECRET_NAME=$2     # Secret name/key
SECRET_VALUE=$3    # Secret value
DEBUG="${@: -1}"   # Optional last parameter 'debug'

# ============ DEBUG MODE ============
if [[ "$DEBUG" == "debug" || "$DEBUG" == "true" ]]; then
  echo "🔍 Running in debug mode" >&2
  set -x
fi

function echod() {
  echo "$@" >&2
}

# ============ VALIDATION ============
if [[ -z "$VAULT_NAME" || -z "$SECRET_NAME" || -z "$SECRET_VALUE" ]]; then
  echod "❌ Missing required parameters."
  echod "Usage: ./storeAzureSecret.sh <vault_name> <secret_name> <secret_value> [debug]"
  exit 1
fi

# ============ STORE SECRET ============
echod "🔐 Storing secret '$SECRET_NAME' in vault '$VAULT_NAME'..."
az keyvault secret set --vault-name "$VAULT_NAME" --name "$SECRET_NAME" --value "$SECRET_VALUE" --only-show-errors >/dev/null

if [ $? -eq 0 ]; then
  echod "✅ Secret '$SECRET_NAME' successfully stored."
else
  echod "❌ Failed to store secret '$SECRET_NAME'."
fi

