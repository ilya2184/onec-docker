function Read-EnvFile {
    
    $envFilePath = ".env"

    # Проверка на отсутствие .env файла
    if (-not (Test-Path $envFilePath)) {
        throw "There is no file: $envFilePath"
    }

    # Чтение .env файла и загрузка переменных окружения
    Get-Content $envFilePath | ForEach-Object {
        if ($_ -match '^(?<key>[^=]+)=(?<value>.*)$') {
            $key = $matches['key'].Trim()
            $value = $matches['value'].Trim()
            [System.Environment]::SetEnvironmentVariable($key, $value)
        }
    }
}

function Test-DockerRegistryLogin {

    if (-not [string]::IsNullOrEmpty($env:DOCKER_LOGIN) -and -not [string]::IsNullOrEmpty($env:DOCKER_PASSWORD) -and -not [string]::IsNullOrEmpty($env:DOCKER_REGISTRY_URL)) {
        docker login -u $env:DOCKER_LOGIN -p $env:DOCKER_PASSWORD $env:DOCKER_REGISTRY_URL
        if ($LASTEXITCODE -ne 0) {
            throw "Docker login failed"
        }
    }

}

function Get-YardName {
    return "$($env:DOCKER_REGISTRY_URL)/yard:latest"
}

function Build-Yard {

    docker build `
        --build-arg DOCKER_REGISTRY_URL=library `
        --build-arg BASE_IMAGE=ubuntu `
        --build-arg BASE_TAG=20.04 `
        --build-arg ONESCRIPT_PACKAGES="yard" `
        --tag "$($env:DOCKER_REGISTRY_URL)/oscript-downloader:latest" `
        --file oscript/Dockerfile .

    # строим проверяем обёртку для загрузки дистрибутивов Onescript-yard
    
    docker build `
        --build-arg DOCKER_REGISTRY_URL=$env:DOCKER_REGISTRY_URL `
        --build-arg BASE_IMAGE=oscript-downloader `
        --build-arg BASE_TAG=latest `
        --tag (Get-YardName) `
        --file oscript-yard/Dockerfile .

    docker push (Get-YardName)
    
}

function Get-DistribByYard {
    param (
        [string]$distrName,
        [string]$distrVersion,
        [string]$distrPath
    )

    # загружаем дистрибутив если его ещё нет
    docker run --rm -v "${distrPath}:/tmp/downloads" (Get-YardName) `
        $($env:ONEC_USERNAME) $($env:ONEC_PASSWORD) $distrVersion $distrName
    
}

function Build-DistribWebServer {
    docker build -t distr_server -f distr-server/Dockerfile .
}

function Start-DistribWebServer {
    param (
        [string]$distrPath,
        [string]$distrWebPort
    )

    docker run --rm --name distr_server -d -v "${distrPath}:/distr" -p ${distrWebPort}:5000 distr_server
    Write-Host "distr server runned for $distrPath on host port $distrWebPort"
}

function Stop-DistribWebServer {
    docker stop distr_server
    Write-Host "distr server stopped"
}

function Build-DockerImage {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("edt", "onec-server", "crs", "crs-apache", "onec-client", "onec-client-vnc")]
        [string]$buildType,
        [string]$distrHost,
        [string]$distrPath
    )

    switch ($buildType) {
        "edt" {
            $distrName = "edt"
            $distrVersion = $env:EDT_VERSION
            $EDT_MAJOR_VERSION = $env:EDT_VERSION.Split('.')[0]
            if ([int]$EDT_MAJOR_VERSION -ge 2024) {
                $baseImage = "bellsoft/liberica-openjdk-debian"
                $baseTag = "17.0.14"
            } else {
                $baseImage = "eclipse-temurin"
                $baseTag = "11"
            }
            $tag = "$($env:DOCKER_REGISTRY_URL)/edt:$distrVersion"
            $dockerfile = "edt/Dockerfile"
        }
        "onec-server" {
            $distrName = "server"
            $distrVersion = $env:ONEC_VERSION
            $baseImage = "ubuntu"
            $baseTag = "20.04"
            $tag = "$($env:DOCKER_REGISTRY_URL)/onec-server:$distrVersion"
            $dockerfile = "server/Dockerfile"
        }
        "crs" {
            $distrName = "server"
            $distrVersion = $env:ONEC_VERSION
            $baseImage = "onec-server"
            $baseTag = $env:ONEC_VERSION
            $tag = "$($env:DOCKER_REGISTRY_URL)/crs:$distrVersion"
            $dockerfile = "crs/Dockerfile"
        }
        "crs-apache" {
            $distrName = "server"
            $distrVersion = $env:ONEC_VERSION
            $baseImage = "crs"
            $baseTag = $env:ONEC_VERSION
            $tag = "$($env:DOCKER_REGISTRY_URL)/crs-apache:$distrVersion"
            $dockerfile = "crs-apache/Dockerfile"
        }
        "onec-client" {
            $distrName = "client"
            $distrVersion = $env:ONEC_VERSION
            $baseImage = "ubuntu"
            $baseTag = "20.04"
            $tag = "$($env:DOCKER_REGISTRY_URL)/onec-client:$distrVersion"
            $dockerfile = "client/Dockerfile"
        }
        "onec-client-vnc" {
            $distrName = "client"
            $distrVersion = $env:ONEC_VERSION
            $baseImage = "onec-client"
            $baseTag = $env:ONEC_VERSION
            $tag = "$($env:DOCKER_REGISTRY_URL)/onec-client-vnc:$distrVersion"
            $dockerfile = "client-vnc/Dockerfile"
        }
    }

    Get-DistribByYard -distrName $distrName -distrVersion $distrVersion -distrPath $distrPath
    
    docker build `
        --build-arg DISTR_HOST=$distrHost `
        --build-arg DISTR_VERSION=$distrVersion `
        --build-arg DOCKER_REGISTRY_URL=$env:DOCKER_REGISTRY_URL `
        --build-arg BASE_IMAGE=$baseImage `
        --build-arg BASE_TAG=$baseTag `
        --tag $tag `
        --file $dockerfile .

    docker push $tag
}