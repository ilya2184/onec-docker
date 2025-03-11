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