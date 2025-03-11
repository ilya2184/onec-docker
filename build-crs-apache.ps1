Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin

docker build `
    --build-arg ONEC_VERSION=$env:ONEC_VERSION `
    --build-arg DOCKER_REGISTRY_URL=$env:DOCKER_REGISTRY_URL `
    --build-arg BASE_TAG=$env:ONEC_VERSION `
    --tag "$($env:DOCKER_REGISTRY_URL)/crs-apache:$($env:ONEC_VERSION)" `
    --file crs-apache/Dockerfile .

docker push "$($env:DOCKER_REGISTRY_URL)/crs-apache:$($env:ONEC_VERSION)"
