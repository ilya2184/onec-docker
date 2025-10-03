Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin

docker build `
    --tag "$($env:DOCKER_REGISTRY_URL)/pusk:1.2.3" `
    --file pusk/Dockerfile .

docker push "$($env:DOCKER_REGISTRY_URL)/pusk:1.2.3"