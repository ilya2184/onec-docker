Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin
Build-Yard
$distrPath = Join-Path -Path $PSScriptRoot -ChildPath "distr"
Start-DistribWebServer -distrPath $distrPath -distrWebPort 8088
# как обращщаться к серверу с дистрибутивами изнетри контейнера сборки
$distrHost = "host.docker.internal:8088"

# При сборке ЕДТ 1ce-installer-cli ищется и сохраняется в каталоге distr/DevelopmentTools10/{ВЕРСИЯ}
#  например distr/DevelopmentTools10/2024.2.3

Get-DistribByYard -buildType "edt" -distrPath $distrPath
Build-DockerImage -buildType "edt" -distrHost $distrHost

# При сборке 1С *.run ищется и сохраняется в каталоге distr/Platform83/{ВЕРСИЯ}
#  например distr/Platform83/8.3.25.1546

# Сначала сервер, поверх него сервер хранилища, поверх него сервер с apache
Get-DistribByYard -buildType "onec-server" -distrPath $distrPath
Build-DockerImage -buildType "onec-server" -distrHost $distrHost
Build-DockerImage -buildType "crs" -distrHost $distrHost
Build-DockerImage -buildType "crs-apache" -distrHost $distrHost

# При сборке клиента 1C *.run ищется и сохраняется в каталоге distr/Client83/{ВЕРСИЯ}
#  например distr/Platform83/8.3.25.1546

# Сначала клиент, поверх него клиент с vnc
Get-DistribByYard -buildType "onec-client" -distrPath $distrPath
Build-DockerImage -buildType "onec-client" -distrHost $distrHost
Build-DockerImage -buildType "onec-client-vnc" -distrHost $distrHost

Stop-DistribWebServer