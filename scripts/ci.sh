#!/bin/bash

#---------------
#- script-wide 
#- constants and 
#- variables
#-
SONAR_URL="https://sonarcloud.io"
ORGANIZATION=""
SONAR_PROJECT_NAME=""


#---------------

#---------------
#- sets the branch
#- name specifier
#- for the sonar
#- cli
function setBranchSpecifier {
    if [[ $1 = "master" ]]; then
        BRANCH_SPECIFIER="/d:sonar.branch.name=$1"
    else
        BRANCH_SPECIFIER="/d:sonar.pullrequest.github.repository=$GITHUB_REPOSITORY_IDENTIFIER \
        /d:sonar.pullrequest.key=$GITHUB_PULLREQUEST_NUMBER \
        /d:sonar.pullrequest.branch=$GITHUB_PULLREQUEST_BRANCH_REF \
        /d:sonar.pullrequest.base=master"
    fi
}

#---------------

#---------------
#- Parses the version tag
#-
#- param $1 a .csproj file
#---------------
function parseCsProjVersion {
    read_dom () {
        local IFS=\>
        read -d \< ENTITY CONTENT
    }

    while read_dom; do
    if [[ $ENTITY = "Version" ]]; then
        echo $CONTENT
    fi
    done < "$1"
}

#---------------

#---------------
#- run sonar 
#- analysis
#---------------
function sonar {
    dir="$(pwd)"
    setBranchSpecifier $GITHUB_BRANCH_NAME
    version=$(parseCsProjVersion "src/$SONAR_PROJECT_NAME.csproj")

    echo "===./quality.sh PARAMETER VALUES==="
    echo "sonar url: ${SONAR_URL}"
    echo "sonar org: ${ORGANIZATION}"
    echo "sonar project key: ${SONAR_PROJECT_KEY}"
    echo "sonar project name: ${SONAR_PROJECT_NAME}"
    echo "github repository identifier: ${GITHUB_REPOSITORY}"
    echo "github branch ref: ${GITHUB_PULLREQUEST_BRANCH_REF}"
    echo "git branch name: ${GITHUB_BRANCH_NAME}"
    echo "git branch pull request number: ${GITHUB_PULLREQUEST_NUMBER}"

    echo "sonar project version: ${version}"
    echo "branch specifier: ${BRANCH_SPECIFIER}"

    # doc for sonarcloud analysis: https://sonarcloud.io/documentation/analysis/overview/

    dotnet sonarscanner begin /o:"${ORGANIZATION}" /k:"${SONAR_PROJECT_KEY}" /n:"${SONAR_PROJECT_NAME}" /v:"${version}" /d:sonar.host.url="${SONAR_URL}" /d:sonar.login="${SONAR_TOKEN}" /d:sonar.language=cs /d:sonar.exclusions=**/bin/**/*,**/obj/**/*,test/**/* /d:sonar.cs.opencover.reportsPaths="${dir}/lcov.opencover.xml" ${BRANCH_SPECIFIER}
        dotnet restore
        dotnet build
        dotnet test ./test/*.test.csproj --no-build /p:CollectCoverage=true /p:CoverletOutputFormat=\"opencover,lcov\" /p:CoverletOutput=../lcov
    dotnet sonarscanner end /d:sonar.login="${SONAR_TOKEN}"
    rm -f lcov.info lcov.opencover.xml
}
#---------------

#---------------
function setScriptEnvironmentVariables {
    GITHUB_REPOSITORY_IDENTIFIER="$GITHUB_REPOSITORY" 
    ORGANIZATION=${GITHUB_REPOSITORY_IDENTIFIER%%/*} # retain the part before the last slash 
    SONAR_PROJECT_NAME=${GITHUB_REPOSITORY_IDENTIFIER##*/}  # retain the part after the last slash
    SONAR_PROJECT_KEY="${ORGANIZATION}_${SONAR_PROJECT_NAME}"
    GITHUB_PULLREQUEST_BRANCH_REF="$GITHUB_REF"
    GITHUB_BRANCH_NAME=${GITHUB_PULLREQUEST_BRANCH_REF##*/}  # retain the part after the last slash 
    GITHUB_PULLREQUEST_NUMBER=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
}
#---------------

#---------------
#- Main function
function main {

    # build.
    dotnet build ./src/*.csproj --configuration Release

    # automated unit tests.
    dotnet test ./test/*.csproj

    # quality analysis
    dotnet tool install dotnet-sonarscanner --tool-path "$HOME/.dotnet/tools"
    export PATH="$PATH:$HOME/.dotnet/tools"
    sonar

    # package.
    dotnet pack ./src/*.csproj --configuration Release

    # add nuget source
    nuget sources Add -Name "github" -Source "https://nuget.pkg.github.com/$ORGANIZATION/index.json" -Username "aaroncope@gmail.com" -Password $GITHUB_TOKEN

    # push
    nuget push -Source "github" ./src/**/*/*.nupkg -SkipDuplicate
}
#---------------

setScriptEnvironmentVariables
main