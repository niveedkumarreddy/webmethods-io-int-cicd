#!/bin/bash

#############################################################################
#                                                                           #
# deleteProjectSecrets.sh : Delelets all the secrets for a project          #
#                                                                           #
#############################################################################

# Usage: ./deleteProjectSecrets.sh <vault_name> <project_name> [--purge]

VAULT_NAME="$1"
PROJECT_NAME="$2"
PURGE=false

if [[ "$3" == "--purge" ]]; then
  PURGE=true
fi

if [[ -z "$VAULT_NAME" || -z "$PROJECT_NAME" ]]; then
  echo "Usage: ./deleteProjectSecrets.sh <vault_name> <project_name> [--purge]"
  exit 1
fi

echo "🔍 Fetching secrets for project: $PROJECT_NAME from vault: $VAULT_NAME..."
[[ "$PURGE" == "true" ]] && echo "⚠️  Purge enabled: secrets will be permanently removed."

# Normalize project name: underscores to hyphens
SEARCH_PATTERN=$(echo "$PROJECT_NAME" | sed 's/_/-/g')

# ===== Active Secrets Deletion =====
secret_names=$(az keyvault secret list --vault-name "$VAULT_NAME" --query "[].name" -o tsv)

found=0
while IFS= read -r secret_name; do
  if [[ "$secret_name" == *"$SEARCH_PATTERN"* ]]; then
    found=1
    echo "🗑️  Deleting secret: $secret_name"
    az keyvault secret delete --vault-name "$VAULT_NAME" --name "$secret_name"

    if [[ "$PURGE" == "true" ]]; then
      echo "🔥 Purging deleted secret: $secret_name"
      az keyvault secret purge --vault-name "$VAULT_NAME" --name "$secret_name"
    fi
  fi
done <<< "$secret_names"

if [[ $found -eq 0 ]]; then
  echo "ℹ️  No active secrets found matching pattern: $SEARCH_PATTERN"
fi

# ===== Purge Orphaned Soft-Deleted Secrets =====
if [[ "$PURGE" == "true" ]]; then
  echo "🛠️  Checking for soft-deleted secrets to purge..."

  deleted_secrets=$(az keyvault secret list-deleted --vault-name "$VAULT_NAME" --query "[].name" -o tsv)

  while IFS= read -r deleted_secret; do
    if [[ "$deleted_secret" == *"$SEARCH_PATTERN"* ]]; then
      echo "🔥 Purging soft-deleted secret: $deleted_secret"
      az keyvault secret purge --vault-name "$VAULT_NAME" --name "$deleted_secret"
    fi
  done <<< "$deleted_secrets"

  echo "✅ Purging of soft-deleted secrets complete."
fi

echo "✅ Completed cleanup for project: $PROJECT_NAME"