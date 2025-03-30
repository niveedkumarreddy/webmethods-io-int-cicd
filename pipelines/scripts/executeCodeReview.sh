#!/bin/bash

#############################################################################
#                                                                           #
# executeCodeReview.sh :execute code review                                 #
#                                                                           #
#############################################################################

HOME_DIR=$1
individualAssetExport=$2
repoName=$3
isccrImg=$4
isccrDir=$5
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
  # Unzip all exports zips
  find ${repoName}/assets/flowservices -name '*.zip' -exec sh -c 'unzip -d "${1%*.zip}" "$1"' _ {} \;
  # Unzip all pkg_ zips
  find ${repoName}/assets/flowservices -name '*.zip' -exec sh -c 'unzip -o -d "${1%*.zip}" "$1"' _ {} \;
   # Move all pkg_ to review folder
  find ${repoName}/assets/flowservices/* -type d -name 'pkg_*' -exec cp -r {} review \;
}

function runCodeReview(){
  HOME_DIR=$1
  isccrDir=$2
  isccrImg=$3
  cd ${HOME_DIR}/${isccr_DIR}
  docker build -t ${isccrImg} .
  docker run -v ./options:/mnt/code_review_options -v ./review:/mnt/code_review -v ./results:/mnt/code_review_results chini007/isccr pkg_ pkg_
  cp ${HOME_DIR}/results/*junit.xml ${HOME_DIR}/results/junit/
}



cd ${HOME_DIR}
mkdir -p review
mkdir -p results/junit
mkdir -p options

prepareProjectZip ${repoName} ${repoName} ${individualAssetExport}
runCodeReview ${HOME_DIR} ${isccrDir} ${isccrImg}
cd ${HOME_DIR}/results/junit

set +x


