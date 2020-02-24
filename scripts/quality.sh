#!/bin/bash

BRANCH_SPECIFIER=""

#---------------
#- argument parsing
#---------------
args=()

while [[ $# > 0 ]]
do
key="$1"

case $key in 
    -u|--sonar-host-url)
    SONAR_HOST_URL="$2"
    shift #past arg
    ;;
    -t|--sonar-login-token)
    SONAR_LOGIN_TOKEN="$2"
    shift #past arg
    ;;
    -o|--sonar-organization)
    SONAR_ORGANIZATION="$2"
    shift #past arg
    ;;
    -k|--sonar-project-key)
    SONAR_PROJECT_KEY="$2"
    shift #past arg
    ;;
    -n|--sonar-project-name)
    SONAR_PROJECT_NAME="$2"
    shift #past arg
    ;;
    -b|--sonar-branch-name)
    SONAR_BRANCH_NAME="$2"
    shift #past arg
    ;;
    *)
        #unknown option
        args+=($1)
    ;;
esac
shift # past arg or value
done

#---------------
#- Main function
function main {
    dir="$(pwd)"
    setBranchSpecifier $SONAR_BRANCH_NAME
    version=$(parseCsProjVersion "src/$SONAR_PROJECT_NAME.csproj")

    echo "sonar url: ${SONAR_HOST_URL}"
    echo "sonar org: ${SONAR_ORGANIZATION}"
    echo "sonar project key: ${SONAR_PROJECT_KEY}"
    echo "sonar project name: ${SONAR_PROJECT_NAME}"
    echo "sonar project version: ${version}"
    echo "git branch: ${BRANCH_SPECIFIER}"

    dotnet sonarscanner begin /o:"${SONAR_ORGANIZATION}" /k:"${SONAR_PROJECT_KEY}" /n:"${SONAR_PROJECT_NAME}" /v:"${version}" /d:sonar.host.url="${SONAR_HOST_URL}" /d:sonar.login="${SONAR_LOGIN_TOKEN}" /d:sonar.language=cs /d:sonar.exclusions=**/bin/**/*,**/obj/**/*,test/**/* /d:sonar.cs.opencover.reportsPaths="${dir}/lcov.opencover.xml" "$BRANCH_SPECIFIER"
    dotnet restore
    dotnet build
    dotnet test ./test/*.test.csproj --no-build /p:CollectCoverage=true /p:CoverletOutputFormat=\"opencover,lcov\" /p:CoverletOutput=../lcov
    dotnet sonarscanner end /d:sonar.login="${SONAR_LOGIN_TOKEN}"
    rm -f lcov.info lcov.opencover.xml
}
#---------------

#---------------
#- sets the branch
#- name specifier
#- for the sonar
#- cli
function setBranchSpecifier {
    #echo "THE BRANCH NAME IS: $1"
    #local branch="/d:sonar.branch.name=$1"
    #if [ $1 = "master" ]; then
    #    BRANCH_SPECIFIER="$branch"
    #else
        BRANCH_SPECIFIER="/d:sonar.branch.name=$1 /d:sonar.branch.target=master"
    #fi
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

main