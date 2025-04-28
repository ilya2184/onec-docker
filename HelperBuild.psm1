function Read-EnvFile {

    <#
    .SYNOPSIS
    Читает .env файл и загружает переменные окружения в текущую сессию.

    .DESCRIPTION
    Эта функция проверяет наличие файла .env в текущем каталоге. 
    Если файл существует, она считывает его построчно, 
    парсит каждую строку и устанавливает переменные окружения в системе.

    .EXAMPLE
    Read-EnvFile
    Загружает переменные окружения из .env файла.

    .PARAMETER None
    Функция не принимает никаких параметров.
    #>    

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

    <#
    .SYNOPSIS
    Проверяет наличие учетных данных и выполняет вход в Docker Registry.

    .DESCRIPTION
    Эта функция проверяет, установлены ли переменные среды DOCKER_LOGIN, 
    DOCKER_PASSWORD и DOCKER_REGISTRY_URL. Если все переменные установлены, 
    функция выполняет команду входа в Docker Registry с использованием 
    указанных учетных данных. В случае неудачного входа будет выброшено 
    исключение с сообщением об ошибке.

    .EXAMPLE
    Test-DockerRegistryLogin
    Проверяет учетные данные Docker и выполняет вход в Docker Registry.

    .PARAMETER None
    Функция не принимает никаких параметров.
    #>

    if (-not [string]::IsNullOrEmpty($env:DOCKER_LOGIN) -and -not [string]::IsNullOrEmpty($env:DOCKER_PASSWORD) -and -not [string]::IsNullOrEmpty($env:DOCKER_REGISTRY_URL)) {
        docker login -u $env:DOCKER_LOGIN -p $env:DOCKER_PASSWORD $env:DOCKER_REGISTRY_URL
        if ($LASTEXITCODE -ne 0) {
            throw "Docker login failed"
        }
    }

}

function Get-YardName {

   <#
    .SYNOPSIS
    Возвращает полное имя образа "yard" в Docker Registry.

    .DESCRIPTION
    Эта функция формирует и возвращает строку, представляющую полное 
    имя образа "yard" с тегом "latest", используя переменную среды 
    DOCKER_REGISTRY_URL. Если переменная окружения не установлена, 
    функция вернет значение, состоящее из строки и отсутствующего URL.
    Требует переменной среды DOCKER_REGISTRY_URL

    .EXAMPLE
    $yardName = Get-YardName
    Возвращает полное имя образа "yard" для дальнейшего использования.

    .PARAMETER None
    Функция не принимает никаких параметров.
    #>

    return "$($env:DOCKER_REGISTRY_URL)/yard:latest"
}

function Build-Yard {
    
    <#
    .SYNOPSIS
    Строит образы Docker для приложения Onescript-yard и загружает их в Docker Registry.

    .DESCRIPTION
    Эта функция выполняет два этапа сборки Docker:
    1. Строит базовый образ "oscript-downloader" с заданными аргументами сборки, 
       включая URL реестра Docker, базовый образ и теги.
    2. Строит образ "yard" на основе ранее собранного "oscript-downloader" и 
       загружает его в Docker Registry.
    Требует переменной среды DOCKER_REGISTRY_URL

    .EXAMPLE
    Build-Yard
    Строит и загружает образы Docker для Onescript-yard.

    .PARAMETER None
    Функция не принимает никаких параметров.
    #>
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

    <#
    .SYNOPSIS
    Загружает дистрибутив через Docker контейнер.

    .DESCRIPTION
    Эта функция запускает контейнер Docker для загрузки указанного дистрибутива 
    из releases.1c.ru. Если дистрибутив еще не загружен, он будет загружен 
    в указанный путь. Функция использует имя образа, полученное от функции 
    Get-YardName, и передает учетные данные для аутентификации.
    Требует наличия образа Get-YardName.

    .PARAMETER distrName
    Имя дистрибутива, который необходимо загрузить.

    .PARAMETER distrVersion
    Версия дистрибутива, который необходимо загрузить.

    .PARAMETER distrPath
    Путь к директории на хосте, куда будет загружен дистрибутив.

    .EXAMPLE
    Get-DistribByYard -distrName "edt" -distrVersion "2024.2.3" -distrPath "D:\Projects\onec-docker-my\distr"
    Загружает дистрибутив ЕДТ версии 2024.2.3 в папку "D:\Projects\onec-docker-my\distr\DevelopmentTools10\2024.2.3".
    Get-DistribByYard -distrName "server" -distrVersion "8.3.25.1546" -distrPath "D:\Projects\onec-docker-my\distr"
    Загружает дистрибутив 1C для Linux x86_64 версии 2024.2.3 в папку "D:\Projects\onec-docker-my\distr\Platform83\8.3.25.1546".

    #>

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

    <#
    .SYNOPSIS
    Строит образ Docker для веб-сервера дистрибутива.

    .DESCRIPTION
    Эта функция выполняет сборку Docker образа для веб-сервера дистрибутива, 
    используя указанный Dockerfile. Образ будет помечен тегом "distr_server".

    .EXAMPLE
    Build-DistribWebServer
    Строит образ Docker для веб-сервера дистрибутива.

    .PARAMETER None
    Функция не принимает никаких параметров.
    #>

    docker build -t distr_server -f distr-server/Dockerfile .
}

function Start-DistribWebServer {

    <#
    .SYNOPSIS
    Запускает контейнер Docker для веб-сервера дистрибутива.

    .DESCRIPTION
    Эта функция создает и запускает экземпляр контейнера Docker для веб-сервера дистрибутива.
    Для получения дистрибутивов с помошью wget --recursive при сборках контейнеров ЕДТ и 1С

    .PARAMETER distrPath
    Путь к директории на хосте, который будет смонтирован в контейнере.

    .PARAMETER distrWebPort
    Порт на хосте, который будет перенаправлен на порт 5000 в контейнере.

    .EXAMPLE
    Start-DistribWebServer -distrPath "D:\Projects\onec-docker-my\distr" -distrWebPort 8080
    Запускает веб-сервер дистрибутива, смонтировав директорию "D:\Projects\onec-docker-my\distr".

    #>

    param (
        [string]$distrPath,
        [string]$distrWebPort
    )

    docker run --rm --name distr_server -d -v "${distrPath}:/distr" -p ${distrWebPort}:5000 distr_server
    Write-Host "distr server runned for $distrPath on host port $distrWebPort"
}

function Stop-DistribWebServer {

    <#
    .SYNOPSIS
    Останавливает запущенный контейнер веб-сервера дистрибутива.

    .DESCRIPTION
    Эта функция останавливает контейнер Docker с именем "distr_server". 
    После успешной остановки выводится сообщение о том, что веб-сервер остановлен.

    .EXAMPLE
    Stop-DistribWebServer
    Останавливает контейнер веб-сервера дистрибутива.

    .PARAMETER None
    Функция не принимает никаких параметров.
    #>

    docker stop distr_server
    Write-Host "distr server stopped"
}

function Build-DockerImage {

    <#
    .SYNOPSIS
    Строит и загружает Docker образ в зависимости от указанного типа сборки.

    .DESCRIPTION
    Эта функция выполняет сборку Docker образа в зависимости от 
    заданного параметра $buildType. Она поддерживает несколько типов 
    сборки:
        * "edt" - ЕДТ,
        * "onec-server" - сервер 1С,
        * "crs" - сервер хранилища 1С на основе сервера 1С,
        * "crs-apache" - веб-сервер хранилища 1С на основе сервера хранилища 1С,
        * "onec-client" - клиент 1С (конфигуратор, толстый, тонкий) без интерфейса
        * "onec-client-vnc" - клиент 1С с сервером VNC для "посмотреть".
    В зависимости от выбранного типа, функция 
    устанавливает соответствующие переменные, такие как имя дистрибутива, 
    его версия, базовый образ и Dockerfile. После этого она вызывает 
    функцию Get-DistribByYard для загрузки необходимых дистрибутивов, 
    строит образ Docker и загружает его в указанный реестр.

    .PARAMETER buildType
    Тип сборки. Обязательный параметр. Возможные значения: 
    "edt", "onec-server", "crs", "crs-apache", "onec-client", "onec-client-vnc".

    .PARAMETER distrHost
    Хост для дистрибутива - как сервер дистрибутива будет виден при изнутри контейнера сборки.
    Используется в качестве аргумента для сборки.

    .PARAMETER distrPath
    Путь к директории "distr", где будут размещены загруженные дистрибутивы.

    .EXAMPLE
    Build-DockerImage -buildType "onec-client" -distrHost "host.docker.internal:8080" -distrPath "D:\Projects\onec-docker-my\distr"
    Строит образ Docker для клиента 1C и загружает его в реестр.
    #>

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
    
    docker build --no-cache `
        --build-arg DISTR_HOST=$distrHost `
        --build-arg DISTR_VERSION=$distrVersion `
        --build-arg DOCKER_REGISTRY_URL=$env:DOCKER_REGISTRY_URL `
        --build-arg BASE_IMAGE=$baseImage `
        --build-arg BASE_TAG=$baseTag `
        --tag $tag `
        --file $dockerfile .

    docker push $tag
}