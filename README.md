# dependency ![ci](https://github.com/aaronlcope/dependency/workflows/ci/badge.svg) 

## quality outlook
[![SonarCloud](https://sonarcloud.io/images/project_badges/sonarcloud-orange.svg)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)

[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=reliability_rating)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=sqale_rating)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=security_rating)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=alert_status)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)

[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=bugs)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=code_smells)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=vulnerabilities)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=sqale_index)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)

[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=coverage)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=aaronlcope_dependency&metric=duplicated_lines_density)](https://sonarcloud.io/dashboard?id=aaronlcope_dependency)


This is a very simple example that illustrates some core tenants of continuous integration with microservices built in dotnet core.

### sample continuous integration workflow
- Inspect the .github/workflows/ci.yml file.

- By default, GitHub invokes this action on the events that are listened to, defined in this file. We are listening to: 
    - "push" events on the master branch.
    - "pull_request" events that are in the "opened, edited, synchronize, and reopened" states.

- The yml job "ci" runs on latest ubuntu and has three steps: 
    1. Sets up the dotnet core runtime on the linux host
    2. Sets up the nuget client on the linux host
    3. Runs a script (which is present in the repo), called ci.sh. It will pass some environment variables to this script which will be used to derive information necessary to completing all of the continuous integration steps.

- Finally, all of the actual step of continuous integration are performed inside the ci.sh bash script:
    - build
    - test
    - quality analysis
    - package
    - push to github packages