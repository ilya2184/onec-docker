Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin
Build-Yard
$distrPath = Join-Path -Path $PSScriptRoot -ChildPath "distr"
Start-DistribWebServer -distrPath $distrPath -distrWebPort 8088
$distrHost = "host.docker.internal:8088"

# тебуется Build-DockerImage -buildType "onec-client" -distrHost $distrHost
Build-DockerImage -buildType "onec-client-vnc" -distrHost $distrHost

Stop-DistribWebServer