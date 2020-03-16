#!/usr/bin/env bash

######################################################################################################
# Builds a DOTNET CLI based CSPROJ and sends successful artifacts (nupkg files) to a NuGet repository. 
#
# This script's primary purpose is to combine all the steps necessary for a dotnet core ci build
# and package them into a single GitHub Action so that it can be reused across GitHub repositories.
#
# SCRIPT: ci.sh
# AUTHOR: aaronlcope
# DATE: 03/12/2020
######################################################################################################

#-----------------------------------------------------------------------------------------------------
#-  CONSTANTS
#-----------------------------------------------------------------------------------------------------
SONAR_URL="https://sonarcloud.io"

#-----------------------------------------------------------------------------------------------------
#-  VARIABLES (set later in setScriptEnvironmentVariables)
#-----------------------------------------------------------------------------------------------------
GITHUB_REPOSITORY_IDENTIFIER=""
ORGANIZATION=""
SONAR_PROJECT_NAME=""
SONAR_PROJECT_KEY=""
GITHUB_PULLREQUEST_BRANCH_REF=""
GITHUB_BRANCH_NAME=""
GITHUB_PULLREQUEST_NUMBER=""
SONAR_CLOUD_AUTH_TOKEN=""

#---------------

#-----------------------------------------------------------------------------------------------------
#-  ARGUMENT PARSING
#-----------------------------------------------------------------------------------------------------
args=()

# Use > 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use > 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to > 0 the /etc/hosts part is not recognized ( may be a bug )
while [[ $# > 0 ]]
do
key="$1"

case $key in
    --skip-unit-tests)
    SKIP_UNIT_TESTS=YES
    ;;
    --skip-sonar-cloud-analysis)
    SKIP_SONAR_CLOUD_ANALYSIS=YES
    ;;
    --skip-nuget-packaging)
    SKIP_NUGET_PACKAGING=YES
    ;;
    --sonar-cloud-auth-token)
    SONAR_CLOUD_AUTH_TOKEN="$2"
    shift # past argument
    ;;
    *)
       #unknown option
       args+=($1)
    ;;
esac
shift # past argument or value
done

#-----------------------------------------------------------------------------------------------------
#-  MAIN FUNCTIONS
#-----------------------------------------------------------------------------------------------------

#-------------------------------------------------------
#- Main function
#
#- performs:
#  dotnet build, test, dotnet-sonarscanner, pack, push 
#- installs:
#- dotnet-sonarscanner
#-------------------------------------------------------
function main {
    setScriptVariables
    restoreDependencies
    buildSourceCode
    testSourceCode
    scanSourceCode
    packageCompiledSourceCode
}
#---------------

#-------------------------------------------------------
#- restores dependencies of the dotnet core projects
#-------------------------------------------------------
function restoreDependencies {
    # restore dependencies of src and test.
    dotnet restore ./src/*.csproj
    dotnet restore .test/*.csproj
}
#---------------

#-------------------------------------------------------
#- builds the /src dotnet core project
#-------------------------------------------------------
function buildSourceCode {
    # build ./src
    dotnet build ./src/*.csproj --configuration Release
}
#---------------

#-------------------------------------------------------
#- tests the /src dotnet core project by running unit
#- tests under the /test folder
#- 
#- This is optional dependending on whether the caller
#- supplied the flag to skip unit tests to the script
#- (--skip-unit-tests)
#-------------------------------------------------------
function testSourceCode {
    if [ ! -z ${SKIP_UNIT_TESTS+x} ]; then
        echo "Skipping tests at the request of the user."
        return 0;
    else 
        # run automated unit tests.
        dotnet test ./test/*.csproj
    fi
}
#---------------

#-------------------------------------------------------
#- scans the /src dotnet core project by running sonar
#- cloud analysis. a pre-requirement is that a token
#- is configured by the organization so that this script
#- may communicate with sonarcloud.
#- 
#- This is optional dependending on whether the caller
#- supplied the flag to skip sonar cloud analysis 
#- to the script (--skip-sonar-cloud-analysis)
#-------------------------------------------------------
function scanSourceCode {
    if [ ! -z ${SKIP_SONAR_CLOUD_ANALYSIS+x} ]; then
        echo "Skipping sonarcloud analysis at the request of the user."
        return 0;
    else 
        # sonar cloud quality analysis
        dotnet tool install dotnet-sonarscanner --tool-path "$HOME/.dotnet/tools"
        export PATH="$PATH:$HOME/.dotnet/tools"
        sonar
    fi
}
#---------------

#-------------------------------------------------------
#- packages the compiled output of /src code to the
#- contextual github repository that is running 
#- this script.
#- 
#- This is optional dependending on whether the caller
#- supplied the flag to skip nuget packaging
#- to the script (--skip-nuget-packaging)
#-------------------------------------------------------
function packageCompiledSourceCode {
    if [ ! -z ${SKIP_NUGET_PACKAGING+x} ]; then
        echo "Skipping nuget packaging at the request of the user."
        return 0;
    else 
        # package.
        dotnet pack ./src/*.csproj --configuration Release

        # add nuget source
        nuget sources Add -Name "github" -Source "https://nuget.pkg.github.com/$ORGANIZATION/index.json" -Username "aaroncope@gmail.com" -Password $GITHUB_TOKEN

        # push
        nuget push -Source "github" ./src/**/*/*.nupkg -SkipDuplicate
    fi
}
#---------------

#-------------------------------------------------------
#- runs sonar analysis in sonarcloud
#-------------------------------------------------------
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

#-----------------------------------------------------------------------------------------------------
#-  HELPER FUNCTIONS
#-----------------------------------------------------------------------------------------------------

#-------------------------------------------------------
#- sets up the variables to be used in this script
#- by other functions 
#-------------------------------------------------------
function setScriptVariables {
    GITHUB_REPOSITORY_IDENTIFIER="$GITHUB_REPOSITORY" 
    ORGANIZATION=${GITHUB_REPOSITORY_IDENTIFIER%%/*} # retain the part before the last slash 
    SONAR_PROJECT_NAME=${GITHUB_REPOSITORY_IDENTIFIER##*/}  # retain the part after the last slash
    SONAR_PROJECT_KEY="${ORGANIZATION}_${SONAR_PROJECT_NAME}"
    GITHUB_PULLREQUEST_BRANCH_REF="$GITHUB_REF"
    GITHUB_BRANCH_NAME=${GITHUB_PULLREQUEST_BRANCH_REF##*/}  # retain the part after the last slash 
    GITHUB_PULLREQUEST_NUMBER=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
}
#---------------

#-------------------------------------------------------
#- sets the branch name specifier for the sonar cli
#-
#- param $1 the name of a branch
#-------------------------------------------------------
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

#-------------------------------------------------------
#- Parses the version tag
#-
#- param $1 a .csproj file
#-------------------------------------------------------
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

main