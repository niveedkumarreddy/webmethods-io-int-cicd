#!/bin/bash

#############################################################################
#                                                                           #
# setupAzureKeyVault.sh : Initializes Azure Key Vault.                      #
#                                                                           #
#############################################################################



# ============ INPUT PARAMETERS ============
VAULT_NAME=$1             # e.g. kv-myproject
RESOURCE_GROUP=$2         # e.g. my-rg
LOCATION=$3               # e.g. westeurope
TENANT_ID=$4              # Azure AD tenant ID
SP_APP_ID=$5              # Service Principal App ID (aka client_id)
SP_PASSWORD=$6            # Service Principal password (aka client_secret)
ACCESS_OBJECT_ID=$7       # Optional: Object ID to grant access
DEBUG="${@: -1}"          # Optional: enable debug logs




# ============ DEBUG MODE ============
if [[ "$DEBUG" == "debug" || "$DEBUG" == "true" ]]; then
  echo "🔍 Running in debug mode" >&2
  set -x
fi

function echod() {
  echo "$@" >&2
}


# ============ VALIDATION ============
if [[ -z "$VAULT_NAME" || -z "$RESOURCE_GROUP" || -z "$LOCATION" || -z "$TENANT_ID" || -z "$SP_APP_ID" || -z "$SP_PASSWORD" ]]; then
  echod "❌ Missing required parameters."
  echod "Usage: ./setupAzureKeyVault.sh <vault_name> <resource_group> <location> <tenant_id> <sp_app_id> <sp_password> [access_object_id] [debug]"
  exit 1
fi

# ============ TRIM INPUTS ============
SP_APP_ID=$(echo "$SP_APP_ID" | xargs)
ACCESS_OBJECT_ID=$(echo "$ACCESS_OBJECT_ID" | xargs)
TENANT_ID=$(echo "$TENANT_ID" | xargs)


# ============ INSTALL AZ CLI (if missing) ============
if ! command -v az &> /dev/null; then
  echod "📦 Installing Azure CLI..."
  curl -sL https://aka.ms/InstallAzureCLIDeb | bash >/dev/null
  if [ $? -ne 0 ]; then
    echod "❌ Failed to install Azure CLI."
    exit 1
  fi
fi

# ============ LOGIN ============
echod "🔐 Logging into Azure..."
az login --service-principal -u "$SP_APP_ID" -p "$SP_PASSWORD" --tenant "$TENANT_ID" --only-show-errors >/dev/null

if [ $? -ne 0 ]; then
  echod "❌ Azure login failed."
  exit 1
fi

# ============ RESOURCE GROUP ============
echod "📁 Checking resource group..."
az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1 || {
  echod "📁 Resource group not found, creating..."
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --only-show-errors >/dev/null
}

# ============ KEY VAULT ============
echod "🔐 Checking key vault '$VAULT_NAME'..."
if az keyvault show --name "$VAULT_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echod "✅ Key vault '$VAULT_NAME' already exists."
else
  echod "🚀 Creating key vault '$VAULT_NAME'..."
  az keyvault create --name "$VAULT_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --only-show-errors >/dev/null
fi

# ============ RBAC ROLE ASSIGNMENT ============
if [ -n "$ACCESS_OBJECT_ID" ]; then
  echod "🔐 Assigning 'Key Vault Secrets Officer' role to object: $ACCESS_OBJECT_ID"

  VAULT_SCOPE="/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$VAULT_NAME"

az role assignment create \
  --assignee "$SP_APP_ID" \
  --role 'Key Vault Secrets Officer' \
  --scope "$VAULT_SCOPE" --only-show-errors >/dev/null

  echod "✅ RBAC Role assignment complete."
fi

echod "🎉 Azure Key Vault '$VAULT_NAME' is ready to use!"
