Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin

# готовим дистрибутив
#Build-Yard
$distrPath = Join-Path -Path $PSScriptRoot -ChildPath "distr"
Get-DistribByYard -distrName "server" -distrVersion $($env:ONEC_VERSION) -distrPath $distrPath
# Строим и запускаем web-server для дистрибутивов
#Build-DistribWebServer
$distrWebPort = "8088"
Start-DistribWebServer -distrPath $distrPath -distrWebPort $distrWebPort
$thisServer = "host.docker.internal"
$distrHost = $thisServer + ":" + $distrWebPort

docker build `
    --no-cache `
    --build-arg ONEC_VERSION=$env:ONEC_VERSION `
    --build-arg BASE_IMAGE=ubuntu `
    --build-arg BASE_TAG="20.04" `
    --build-arg DISTR_HOST=$distrHost `
    --tag "$($env:DOCKER_REGISTRY_URL)/onec-server:$($env:ONEC_VERSION)" `
    --file server/Dockerfile .

Stop-DistribWebServer
docker push "$($env:DOCKER_REGISTRY_URL)/onec-server:$($env:ONEC_VERSION)"
