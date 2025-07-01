#!/bin/bash

#################################################################################
#                                                                               #
# createFeatureFromProdBranch.sh : Create Feature Branch from Production Branch #
#                                                                               #
#################################################################################

devUser=$1
repoName=$2
configName=$3
configYaml=$4
HOME_DIR=$5
featureBranchName=$6
debug=${@: -1}


# Validate required inputs
[ -z "$devUser" ] && echo "Missing template parameter devUser" >&2 && exit 1
[ -z "$repoName" ] && echo "Missing template parameter repoName" >&2 && exit 1
[ -z "$configName" ] && echo "Missing template parameter configName" >&2 && exit 1
[ -z "$configYaml" ] && echo "Missing template parameter configYaml" >&2 && exit 1
[ -z "$HOME_DIR" ] && echo "Missing template parameter HOME_DIR" >&2 && exit 1
[ -z "$featureBranchName" ] && echo "Missing template parameter featureBranchName" >&2 && exit 1
   
# Debug mode
if [ "$debug" == "debug" ]; then
  echo "......Running in Debug mode ......" >&2
  set -x
fi

function echod() {
  echo "$@" >&2
}

cd ${HOME_DIR}/${repoName}
echo "$configYaml" > "./$configName"

    git config user.email "noemail.com"
    git config user.name "${devUser}"
    git add .
    git commit -m "Initialize: push the project config to repository."
    git push origin HEAD:${featureBranchName}

set +x