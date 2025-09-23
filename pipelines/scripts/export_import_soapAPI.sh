function exportSOAPAsset() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  repoName=$4
  assetID=$5
  assetType=$6
  HOME_DIR=$7

  # Single assetType
  if [[ $assetType = referenceData* ]]; then
    PROJECT_ID_URL=${LOCAL_DEV_URL}/apis/v1/rest/projects/${repoName}

    projectJson=$(curl --location --request GET ${PROJECT_ID_URL} \
      --header 'Content-Type: application/json' \
      --header 'Accept: application/json' \
      -u ${admin_user}:${admin_password})

    projectID=$(echo "$projectJson" | jq -r -c '.output.uid // empty')

    if [ -z "$projectID" ]; then
      echo "Incorrect Project/Repo name"
      exit 1
    fi

    echo "ProjectID: ${projectID}"
  
  else
    EXPORT_URL=${LOCAL_DEV_URL}/apis/v1/rest/projects/${repoName}/export
    soap_api_json="{\"soap_api\": [\"${assetID}\"]}"

    cd ${HOME_DIR}/${repoName}
    mkdir -p ./assets/soap_api
    cd ./assets/soap_api

    echo "soap_api Export: ${EXPORT_URL} with JSON: ${soap_api_json}"
    ls -ltr

    linkJson=$(curl --location --request POST ${EXPORT_URL} \
      --header 'Content-Type: application/json' \
      --header 'Accept: application/json' \
      --data-raw "$soap_api_json" \
      -u ${admin_user}:${admin_password})

    downloadURL=$(echo "$linkJson" | jq -r '.output.download_link')

    regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
    if [[ $downloadURL =~ $regex ]]; then
      echo "Valid Download link retrieved: ${downloadURL}"
    else
      echo "Download link retrieval Failed: ${linkJson}"
      exit 1
    fi

    curl --location --request GET "${downloadURL}" --output ${assetID}.zip

    FILE=./${assetID}.zip
    if [ -f "$FILE" ]; then
      echo "Download succeeded:"
      ls -ltr ./${assetID}.zip
    else
      echo "Download failed"
    fi
  fi

  cd ${HOME_DIR}/${repoName}
}


function importSOAPAsset() {
  LOCAL_DEV_URL=$1
  admin_user=$2
  admin_password=$3
  repoName=$4
  assetID=$5
  assetType=$6
  HOME_DIR=$7

  echo "Current directory: $(pwd)"
  ls -ltr
  echo "AssetType: $assetType"

  if [[ $assetType = soap_api* ]]; then
    IMPORT_URL=${LOCAL_DEV_URL}/apis/v1/rest/project-import
    cd ${HOME_DIR}/${repoName}/assets/soap_api
    echo "SOAP API Import: ${IMPORT_URL}"
    ls -ltr
  fi

  echo "Import URL: ${IMPORT_URL}"
  echo "Working Dir: ${PWD}"

  FILE=./${assetID}.zip
  if [[ $assetType = soap_api* ]]; then
    formKey="project=@${FILE}"
  else
    formKey="recipe=@${FILE}"
  fi

  overwriteKey="overwrite=true"
  echo "Form key: ${formKey}"

  if [ -f "$FILE" ]; then
    echo "$FILE exists. Importing ..."
    importedName=$(curl --location --request POST ${IMPORT_URL} \
      --header 'Content-Type: multipart/form-data' \
      --header 'Accept: application/json' \
      --form ${formKey} --form ${overwriteKey} \
      -u ${admin_user}:${admin_password})

    if [[ $assetType = soap_api* ]]; then
      name=$(echo "$importedName" | jq -r '.output.message // empty')
      success="IMPORT_SUCCESS"
      if [ "$name" == "$success" ]; then
        echo "Import Succeeded: ${importedName}"
      else
        echo "Import Failed: ${importedName}"
      fi
    else
      name=$(echo "$importedName" | jq -r '.output.name // empty')
      if [ -z "$name" ]; then
        echo "Import failed: ${importedName}"
      else
        echo "Import Succeeded: ${importedName}"
      fi
    fi
  else
    echo "$FILE does not exist, Nothing to import"
  fi

  cd ${HOME_DIR}/${repoName}
}
