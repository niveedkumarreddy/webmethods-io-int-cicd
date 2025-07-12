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
  echo "🔍 Running in debug mode"
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
az login --service-principal -u "$SP_APP_ID" -p "$SP_PASSWORD" --tenant "$TENANT_ID" >/dev/null

if [ $? -ne 0 ]; then
  echod "❌ Azure login failed."
  exit 1
fi

# ============ RESOURCE GROUP ============
echod "📁 Checking resource group..."
az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1 || {
  echod "📁 Resource group not found, creating..."
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION" >/dev/null
}

# ============ KEY VAULT ============
echod "🔐 Checking key vault '$VAULT_NAME'..."
if az keyvault show --name "$VAULT_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echod "✅ Key vault '$VAULT_NAME' already exists."
else
  echod "🚀 Creating key vault '$VAULT_NAME'..."
  az keyvault create --name "$VAULT_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" >/dev/null
fi

# ============ ACCESS POLICY ============
if [ -n "$ACCESS_OBJECT_ID" ]; then
  echod "🔐 Assigning secret permissions to object: $ACCESS_OBJECT_ID"
  az keyvault set-policy \
    --name "$VAULT_NAME" \
    --object-id "$ACCESS_OBJECT_ID" \
    --secret-permissions get set list delete \
    >/dev/null
fi

echod "🎉 Azure Key Vault '$VAULT_NAME' is ready to use!"
