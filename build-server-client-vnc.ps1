Import-Module "./HelperBuild.psm1"

Read-EnvFile
Test-DockerRegistryLogin
Build-Yard
$distrPath = Join-Path -Path $PSScriptRoot -ChildPath "distr"
Start-DistribWebServer -distrPath $distrPath -distrWebPort 8088
$distrHost = "host.docker.internal:8088"

Get-DistribByYard -buildType "onec-server-client-vnc" -distrPath $distrPath
Build-DockerImage -buildType "onec-server-client-vnc" -distrHost $distrHost -noCache:$false

Stop-DistribWebServer