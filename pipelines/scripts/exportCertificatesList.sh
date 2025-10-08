#!/bin/bash

#################################################################################################################################################################
# Script Name: exportCertificatesList.sh                                                                                                                          #
# Summary    : Exports all Certificates or a single Certificate configuration from                                                                                  #
#              a given webMethods.io project repository using REST APIs.                                                                                        #
#                                                                                                                                                               #
# Usage      : ./exportCertificatesList.sh <LOCAL_DEV_URL> <admin_user> <admin_password> <repoName> <HOME_DIR> <assetID>                                 #
#                                                                                                                                                               #
# Mandatory Fields:                                                                                                                                             #
#   LOCAL_DEV_URL   - The base URL of the target webMethods.io environment                                                                                      #
#   admin_user      - Administrator username for authentication                                                                                                 #
#   admin_password  - Administrator password for authentication                                                                                                 #
#   repoName        - Repository (project) name in webMethods.io                                                                                                #
#   HOME_DIR        - Local home directory path for storing exports                                                                                             #
#   assetID         - service name of the Certificate                                                                            #
#                                                                                                                                                               #
# Example:                                                                                                                                                      #
#   ./exportCertificatesList.sh "https://mytenant.webmethods.io" "Administrator" "manage" "MyRepo" "/home/user/projects" true                                     #
#                                                                                                                                                               #
#################################################################################################################################################################


set -euo pipefail
set -x

echo "Starting exportCertificatesList.sh"
echo "Arguments: $@"

function exportCertificatesList() {
    LOCAL_DEV_URL=$1
    admin_user=$2
    admin_password=$3
    repoName=$4
    HOME_DIR=$5
    assetID=$6

    echo "Running exportCertificatesList with parameters:"
    echo "LOCAL_DEV_URL=$LOCAL_DEV_URL"
    echo "admin_user=$admin_user"
    echo "admin_password=****"
    echo "repoName=$repoName"
    echo "HOME_DIR=$HOME_DIR"
    echo "assetID=$assetID"

    cd "${HOME_DIR}/${repoName}" || exit 1
    
    if [ -z "$assetID" ] || [ "$assetID" = "null" ]; then
        Certificates_GET_LIST_URL="${LOCAL_DEV_URL}/apis/v1/rest/projects/${repoName}/configurations/certificates"

        CertificatesListJson=$(curl --silent --location --request GET "$Certificates_GET_LIST_URL" \
            --header 'Content-Type: application/json' \
            --header 'Accept: application/json' \
            -u "${admin_user}:${admin_password}")

        CertificatesListExport=$(echo "$CertificatesListJson" | jq '.')

        CertificatesList_file="./assets/projectConfigs/Certificates/CertificatesList.json"

        if [ -z "$CertificatesListExport" ] || [ "$CertificatesListExport" = "null" ]; then
            echo "❌ No Certificates retrieved."
            echo "$CertificatesListJson"
        else
            mkdir -p ./assets/projectConfigs/Certificates
            echo "$CertificatesListExport" | jq '.' > "$CertificatesList_file"
            echo "✅ Certificates List saved to: $CertificatesList_file"
        fi
    else
        exportSingleCertificate "$LOCAL_DEV_URL" "$admin_user" "$admin_password" "$repoName" "$assetID"
    fi
}

function exportSingleCertificate() {
    LOCAL_DEV_URL=$1
    admin_user=$2
    admin_password=$3
    repoName=$4
    assetID=$5

    echo "Running exportSingleCertificate with parameters:"
    echo "LOCAL_DEV_URL=$LOCAL_DEV_URL"
    echo "admin_user=$admin_user"
    echo "admin_password=****"
    echo "repoName=$repoName"
    echo "assetID=$assetID"
    
    SINGLE_Certificates_GET_URL="${LOCAL_DEV_URL}/apis/v1/rest/projects/${repoName}/configurations/certificates/${assetID}?certificateType=${CERT_TYPE}"

    singleCertificateJson=$(curl --silent --location --request GET "$SINGLE_Certificates_GET_URL" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        -u "${admin_user}:${admin_password}")

    if [ -z "$singleCertificateJson" ] || [ "$singleCertificateJson" = "null" ]; then
        echo "⚠️ Skipping: No data for $assetID"
        return
    fi

    if echo "$singleCertificateJson" | jq empty 2>/dev/null; then
        output_dir="./assets/projectConfigs/Certificates"
        mkdir -p "$output_dir"

        individual_file="$output_dir/${assetID}_Certificate.json"
        echo "$singleCertificateJson" | jq '.' > "$individual_file"
        echo "✅ Saved: $individual_file"
    else
        echo "⚠️ Skipping invalid JSON for assetID: $assetID"
    fi
}


# Start execution
exportCertificatesList "$@"
