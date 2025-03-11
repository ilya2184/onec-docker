Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin
Build-Yard
$distrPath = Join-Path -Path $PSScriptRoot -ChildPath "distr"
Start-DistribWebServer -distrPath $distrPath -distrWebPort 8088
$distrHost = "host.docker.internal:8088"

# требуется Build-DockerImage -buildType "onec-server" -distrHost $distrHost
# требуется Build-DockerImage -buildType "crs" -distrHost $distrHost
Build-DockerImage -buildType "crs-apache" -distrHost $distrHost

Stop-DistribWebServer