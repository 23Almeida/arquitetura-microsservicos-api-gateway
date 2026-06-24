param(
    [string]$ZabbixUrl = "http://localhost:8081",
    [string]$User = "Admin",
    [string]$Password = "zabbix",
    [string]$HostName = "api-gateway",
    [string]$GroupName = "Web servers",
    [string]$ScenarioName = "Saude do API Gateway",
    [string]$StepName = "Testar Rota Produtos",
    [string]$ScenarioUrl = "http://api-gateway/produtos",
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"
$script:RequestId = 0
$ApiUrl = "$($ZabbixUrl.TrimEnd('/'))/api_jsonrpc.php"

function Invoke-ZabbixApi {
    param(
        [string]$Method,
        [object]$Params,
        [string]$Auth
    )

    $script:RequestId++
    $body = [ordered]@{
        jsonrpc = "2.0"
        method = $Method
        params = $Params
        id = $script:RequestId
    }

    if ($Auth) {
        $body.auth = $Auth
    }

    $json = $body | ConvertTo-Json -Depth 30
    $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -ContentType "application/json-rpc" -Body $json

    if ($response.error) {
        throw "$($response.error.message): $($response.error.data)"
    }

    return $response.result
}

function Wait-ZabbixApi {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        try {
            $version = Invoke-ZabbixApi -Method "apiinfo.version" -Params @{}
            Write-Host "Zabbix API disponivel. Versao: $version"
            return
        } catch {
            Write-Host "Aguardando Zabbix iniciar em $ZabbixUrl ..."
            Start-Sleep -Seconds 5
        }
    }

    throw "Zabbix nao ficou disponivel em $ZabbixUrl dentro de $TimeoutSeconds segundos."
}

Wait-ZabbixApi

$auth = Invoke-ZabbixApi -Method "user.login" -Params @{
    user = $User
    password = $Password
}

$groups = Invoke-ZabbixApi -Method "hostgroup.get" -Params @{
    output = @("groupid", "name")
    filter = @{ name = @($GroupName) }
} -Auth $auth

if ($groups.Count -eq 0) {
    $createdGroup = Invoke-ZabbixApi -Method "hostgroup.create" -Params @{
        name = $GroupName
    } -Auth $auth
    $groupId = $createdGroup.groupids[0]
    $groupAction = "criado"
} else {
    $groupId = $groups[0].groupid
    $groupAction = "encontrado"
}

$hosts = Invoke-ZabbixApi -Method "host.get" -Params @{
    output = @("hostid", "host", "name")
    filter = @{ host = @($HostName) }
    selectGroups = "extend"
    selectInterfaces = "extend"
} -Auth $auth

if ($hosts.Count -eq 0) {
    $createdHost = Invoke-ZabbixApi -Method "host.create" -Params @{
        host = $HostName
        groups = @(@{ groupid = $groupId })
        interfaces = @(@{
            type = 1
            main = 1
            useip = 1
            ip = "127.0.0.1"
            dns = ""
            port = "10050"
        })
    } -Auth $auth

    $hostId = $createdHost.hostids[0]
    $hostAction = "criado"
} else {
    $hostId = $hosts[0].hostid
    $hostAction = "encontrado"

    $hasGroup = $false
    foreach ($group in $hosts[0].groups) {
        if ($group.groupid -eq $groupId) {
            $hasGroup = $true
        }
    }

    if (-not $hasGroup) {
        $updatedGroups = @()
        foreach ($group in $hosts[0].groups) {
            $updatedGroups += @{ groupid = $group.groupid }
        }
        $updatedGroups += @{ groupid = $groupId }

        Invoke-ZabbixApi -Method "host.update" -Params @{
            hostid = $hostId
            groups = $updatedGroups
        } -Auth $auth | Out-Null
    }
}

$tests = Invoke-ZabbixApi -Method "httptest.get" -Params @{
    output = @("httptestid", "name")
    hostids = @($hostId)
    filter = @{ name = @($ScenarioName) }
    selectSteps = "extend"
} -Auth $auth

$scenarioParams = @{
    name = $ScenarioName
    delay = "1m"
    retries = 1
    steps = @(@{
        name = $StepName
        no = 1
        url = $ScenarioUrl
        status_codes = "200"
    })
}

if ($tests.Count -eq 0) {
    $scenarioParams.hostid = $hostId
    $createdScenario = Invoke-ZabbixApi -Method "httptest.create" -Params $scenarioParams -Auth $auth
    $scenarioId = $createdScenario.httptestids[0]
    $scenarioAction = "criado"
} else {
    $scenarioParams.httptestid = $tests[0].httptestid
    Invoke-ZabbixApi -Method "httptest.update" -Params $scenarioParams -Auth $auth | Out-Null
    $scenarioId = $tests[0].httptestid
    $scenarioAction = "atualizado"
}

Write-Host ""
Write-Host "Configuracao do Zabbix concluida."
Write-Host "Grupo: $GroupName ($groupAction)"
Write-Host "Host: $HostName ($hostAction)"
Write-Host "Web Scenario: $ScenarioName ($scenarioAction)"
Write-Host "Step: $StepName"
Write-Host "URL monitorada: $ScenarioUrl"
Write-Host ""
Write-Host "Depois de cerca de 1 minuto, veja em:"
Write-Host "Monitoring -> Hosts -> $HostName -> Web"
