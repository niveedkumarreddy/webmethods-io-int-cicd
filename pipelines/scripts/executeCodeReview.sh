#!/bin/bash

#############################################################################
#                                                                           #
# executeCodeReview.sh :execute code review                                 #
#                                                                           #
#############################################################################

HOME_DIR=$1
individualAssetExport=$2
repoName=$3
registryUser=$4
registryToken=$5
rigistryHost=$6
isccrImg=$7
isccrDir=$8
debug=${@: -1}

    if [ -z "$HOME_DIR" ]; then
      echo "Missing template parameter HOME_DIR"
      exit 1
    fi
    
    if [ -z "$individualAssetExport" ]; then
      echo "Missing template parameter individualAssetExport"
      exit 1
    fi

    if [ -z "$repoName" ]; then
      echo "Missing template parameter repoName"
      exit 1
    fi

    if [ -z "$isccrImg" ]; then
      echo "Missing template parameter isccrImg"
      exit 1
    fi
    if [ -z "$isccrDir" ]; then
      echo "Missing template parameter isccrDir"
      exit 1
    fi

    if [ "$debug" == "debug" ]; then
      echo "......Running in Debug mode ......"
    fi


function echod(){
  if [ "$debug" == "debug" ]; then
    echo $1
    set -x
  fi
}

function prepareProjectZip(){
  repoName=$1
  individualAssetExport=$2
  if [ ${individualAssetExport} == true ]; then
    # Unzip all exports zips
    find ${repoName}/assets/flowservices -name '*.zip' -exec sh -c 'unzip -d "${1%*.zip}" "$1"' _ {} \;
    # Unzip all pkg_ zips
    find ${repoName}/assets/flowservices -name '*.zip' -exec sh -c 'unzip -o -d "${1%*.zip}" "$1"' _ {} \;
    # Move all pkg_ to review folder
    find ${repoName}/assets/flowservices/* -type d -name 'pkg_*' -exec cp -r {} review \;

    # find all directories named integrations, cd to parent directory and remove all directories except integrations
    find review -type d -name 'integrations' -exec sh -c 'cd $(dirname {}) && rm -rf $(ls -d */ | grep -v integrations)' \;
  else
    unzip ${repoName}/${repoName}.zip -d ${repoName}/
    # unzip all zip files under wmio/$project/deploy-flows    
    find ${repoName}/deploy-flows -name '*.zip' -exec sh -c 'unzip -d "${1%*.zip}" "$1"' _ {} \;

    # find directory starting with pkg_ under deploy-flows and copy the contents review directory
    find ${repoName}/deploy-flows -type d -name 'pkg_*' -exec cp -r {} review \;

    # find all directories named integrations, cd to parent directory and remove all directories except integrations
    find review -type d -name 'integrations' -exec sh -c 'cd $(dirname {}) && rm -rf $(ls -d */ | grep -v integrations)' \;
  fi
}

function runCodeReview(){
  HOME_DIR=$1
  isccrDir=$2
  isccrImg=$3
  # Build docker image
  cd ${HOME_DIR}/${isccrDir}
  docker login -u ${registryUser} -p ${registryToken} ${rigistryHost}
  docker build -t ${isccrImg} .

  cd ${HOME_DIR}
  # Run ISCCR docker instance with mounts
  docker run -v ./options:/mnt/code_review_options -v ./review:/mnt/code_review -v ./results:/mnt/code_review_results ${isccrImg} pkg_ pkg_
  
}



cd ${HOME_DIR}
mkdir -p review
mkdir -p results
mkdir -p options

prepareProjectZip ${repoName} ${individualAssetExport}
runCodeReview ${HOME_DIR} ${isccrDir} ${isccrImg}


set +x


