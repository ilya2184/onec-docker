Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin

# должен быть доступен дистрибутив onec-client
# см. build-client.ps1

docker build `
    --build-arg ONEC_VERSION=$env:ONEC_VERSION `
    --build-arg DOCKER_REGISTRY_URL=$env:DOCKER_REGISTRY_URL `
    --tag "$($env:DOCKER_REGISTRY_URL)/onec-client-vnc:$($env:ONEC_VERSION)" `
    --file client-vnc/Dockerfile .

docker push "$($env:DOCKER_REGISTRY_URL)/onec-client-vnc:$($env:ONEC_VERSION)"
