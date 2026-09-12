[CmdletBinding()]
param(
    [string]$FunctionJson = (Join-Path $PSScriptRoot '..\..\server\config\json\function.json'),
    [string]$RouteJson = (Join-Path $PSScriptRoot '..\..\unityclient\Assets\ProjectX\Resources\Configs\function-routes.json'),
    [string]$OutputJson = (Join-Path $PSScriptRoot '..\..\unityclient\Assets\ProjectX\Resources\Configs\gameplay.json')
)

$ErrorActionPreference = 'Stop'
$functionRows = Get-Content -Raw -Encoding UTF8 -LiteralPath $FunctionJson | ConvertFrom-Json
$routes = Get-Content -Raw -Encoding UTF8 -LiteralPath $RouteJson | ConvertFrom-Json
$functionsById = @{}
foreach ($row in $functionRows) { $functionsById[[int]$row.function_id] = $row }

$output = foreach ($route in $routes) {
    $id = [int]$route.functionId
    if ($id -ge 999 -or -not $functionsById.ContainsKey($id)) { continue }
    $row = $functionsById[$id]
    $levelCondition = @($row.open_condition)[0]
    if (@($levelCondition).Count -lt 2 -or [int]$levelCondition[0] -ne 1) {
        throw "function_id=$id has no level open_condition and cannot be exported to Gameplay."
    }
    [ordered]@{
        id = $id
        name = [string]$row.name
        page = [int]$row.page
        openLevel = [int]$levelCondition[1]
        icon = [string]$row.icon
        description = [string]$row.des
        route = [string]$route.target
        steamEnabled = ([string]$route.kind -ne 'SteamExcluded')
    }
}

$json = $output | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($OutputJson), $json + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false))
Write-Output "Exported $($output.Count) Gameplay routes to $OutputJson"
