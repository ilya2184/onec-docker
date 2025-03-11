Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin

# должен быть доступен дистрибутив onec-client
# см. build-client.ps1

docker build `
    --build-arg ONEC_VERSION=$env:ONEC_VERSION `
    --build-arg DOCKER_REGISTRY_URL=$env:DOCKER_REGISTRY_URL `
    -t "$($env:DOCKER_REGISTRY_URL)onec-client-vnc:$($env:ONEC_VERSION)" `
    -f client/Dockerfile .

docker push "$($env:DOCKER_REGISTRY_URL)/onec-client-vnc:$($env:ONEC_VERSION)"
