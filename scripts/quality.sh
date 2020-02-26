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
    -g|--github-repository-identifier)
    GITHUB_REPOSITORY_IDENTIFIER="$2"
    shift #past arg
    ;;
    -r|--github-pullrequest-branch-ref)
    GITHUB_PULLREQUEST_BRANCH_REF="$2"
    shift #past arg
    ;;
    -b|--github-branch-name)
    GITHUB_BRANCH_NAME="$2"
    shift #past arg
    ;;
    -p|--github-pullrequest-number)
    GITHUB_PULLREQUEST_NUMBER="$2"
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
    setBranchSpecifier $GITHUB_BRANCH_NAME
    version=$(parseCsProjVersion "src/$SONAR_PROJECT_NAME.csproj")

    echo "===./quality.sh PARAMETER VALUES==="
    echo "(-u) sonar url: ${SONAR_HOST_URL}"
    echo "(-t) sonar token: ***masked for your protection***"
    echo "(-o) sonar org: ${SONAR_ORGANIZATION}"
    echo "(-k) sonar project key: ${SONAR_PROJECT_KEY}"
    echo "(-n) sonar project name: ${SONAR_PROJECT_NAME}"
    echo "(-g) github repository identifier: ${GITHUB_REPOSITORY_IDENTIFIER}"
    echo "(-r) github branch ref: ${GITHUB_PULLREQUEST_BRANCH_REF}"
    echo "(-b) git branch name: ${GITHUB_BRANCH_NAME}"
    echo "(-p) git branch pull request number: ${GITHUB_PULLREQUEST_NUMBER}"

    echo "sonar project version: ${version}"
    echo "branch specifier: ${BRANCH_SPECIFIER}"

    # doc for sonarcloud analysis: https://sonarcloud.io/documentation/analysis/overview/

    #dotnet sonarscanner begin /o:"${SONAR_ORGANIZATION}" /k:"${SONAR_PROJECT_KEY}" /n:"${SONAR_PROJECT_NAME}" /v:"${version}" /d:sonar.host.url="${SONAR_HOST_URL}" /d:sonar.login="${SONAR_LOGIN_TOKEN}" /d:sonar.language=cs /d:sonar.exclusions=**/bin/**/*,**/obj/**/*,test/**/* /d:sonar.cs.opencover.reportsPaths="${dir}/lcov.opencover.xml" "$BRANCH_SPECIFIER"
    #    dotnet restore
    #    dotnet build
    #    dotnet test ./test/*.test.csproj --no-build /p:CollectCoverage=true /p:CoverletOutputFormat=\"opencover,lcov\" /p:CoverletOutput=../lcov
    #dotnet sonarscanner end /d:sonar.login="${SONAR_LOGIN_TOKEN}"
    #rm -f lcov.info lcov.opencover.xml
}
#---------------

#---------------
#- sets the branch
#- name specifier
#- for the sonar
#- cli
function setBranchSpecifier {
    local basis="/d:sonar.branch.name=$1"
    if [[ $1 = "master" ]]; then
        BRANCH_SPECIFIER="$basis"
    else
        BRANCH_SPECIFIER="$basis /d:sonar.pullrequest.github.repository=$GITHUB_REPOSITORY_IDENTIFIER \
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

main