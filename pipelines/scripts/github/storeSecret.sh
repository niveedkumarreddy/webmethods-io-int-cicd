#!/bin/bash

#############################################################################
#                                                                           #
# storeSecret.sh : Stores the secret in GITHUB ACTION.                      #
#                                                                           #
#############################################################################

 secretName=$1
 secretValue=$2
 repo_user=$3
 repoName=$4
 PAT=$5
 debug=${@: -1}

# Validate required inputs
[ -z "$secretName" ] && echo "Missing template parameter secretName" >&2 && exit 1
[ -z "$secretValue" ] && echo "Missing template parameter secretValue" >&2 && exit 1
[ -z "$repo_user" ] && echo "Missing template parameter repo_user" >&2 && exit 1
[ -z "$repoName" ] && echo "Missing template parameter repoName" >&2 && exit 1
[ -z "$PAT" ] && echo "Missing template parameter PAT" >&2 && exit 1


# Debug mode
if [ "$debug" == "debug" ]; then
  echo "......Running in Debug mode ......" >&2
  set -x
fi

function echod() {
  echo "$@" >&2
}

  # Get public key (to encrypt secret)
  response=$(curl -s -H "Authorization: token ${PAT}" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/${repo_user}/${repoName}/actions/secrets/public-key)

  keyId=$(echo "$response" | jq -r '.key_id')
  keyValue=$(echo "$response" | jq -r '.key')

  if [[ -z "$keyId" || "$keyId" == "null" ]]; then
    echo "❌ Failed to retrieve repository public key."
    return 1
  fi

  # Encrypt the value using your Python script
  encryptedValue=$(python3.10 ../self/pipelines/scripts/github/encryptGithubSecret.py "${keyValue}" "${secretValue}")

  # Construct the JSON payload
  secretJson=$(jq -n \
    --arg value "$encryptedValue" \
    --arg keyId "$keyId" \
    '{encrypted_value: $value, key_id: $keyId}')

  # Store the secret
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -u ${repo_user}:${PAT} \
    "https://api.github.com/repos/${repo_user}/${repoName}/actions/secrets/${secretName}" \
    -d "$secretJson")

  if [[ "$response" == "201" || "$response" == "204" ]]; then
    echo "✅ Secret '${secretName}' successfully stored in GitHub."
  else
    echo "❌ Failed to store secret '${secretName}'. HTTP status: $response"
  fi