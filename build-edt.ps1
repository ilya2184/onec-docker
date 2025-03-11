Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin
Build-Yard
$distrPath = Join-Path -Path $PSScriptRoot -ChildPath "distr"
Start-DistribWebServer -distrPath $distrPath -distrWebPort 8088
$distrHost = "host.docker.internal:8088"

Build-DockerImage -buildType "edt" -distrHost $distrHost
Build-DockerImage -buildType "onec-server" -distrHost $distrHost
Build-DockerImage -buildType "crs" -distrHost $distrHost
Build-DockerImage -buildType "crs-apache" -distrHost $distrHost
Build-DockerImage -buildType "onec-client" -distrHost $distrHost
Build-DockerImage -buildType "onec-client-vnc" -distrHost $distrHost

Stop-DistribWebServer