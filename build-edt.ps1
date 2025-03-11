Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin

# определяем базовый образ для ЕДТ
$EDT_MAJOR_VERSION = $env:EDT_VERSION.Split('.')[0]
if ([int]$EDT_MAJOR_VERSION -ge 2024) {
    $edtBaseImage = "bellsoft/liberica-openjdk-debian"
    $edtBaseTag = "17.0.14"
} else {
    $env:BASE_IMAGE = "eclipse-temurin"
    $env:BASE_TAG = "11"
}

# готовим дистрибутив
Build-Yard
$distrPath = Join-Path -Path $PSScriptRoot -ChildPath "distr"
Get-DistribByYard -distrName "edt" -distrVersion $($env:EDT_VERSION) -distrPath $distrPath
# Строим и запускаем web-server для дистрибутивов
Build-DistribWebServer
$distrWebPort = "8088"
$thisServer = "host.docker.internal"
Start-DistribWebServer -distrPath $distrPath -distrWebPort $distrWebPort
$distrHost = $thisServer + ":" + $distrWebPort

# строим образ ЕДТ
docker build `
    --build-arg EDT_VERSION=$env:EDT_VERSION `
    --build-arg BASE_IMAGE=$edtBaseImage `
    --build-arg BASE_TAG=$edtBaseTag `
    --build-arg DISTR_HOST=$distrHost `
    --tag "$($env:DOCKER_REGISTRY_URL)/edt:$($env:EDT_VERSION)" `
    --file edt/Dockerfile .

docker push "$($env:DOCKER_REGISTRY_URL)/edt:$($env:EDT_VERSION)"

Stop-DistribWebServer