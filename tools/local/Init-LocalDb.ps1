param(
    [string]$MySqlUser = "root",
    [string]$MySqlPassword = "123456",
    [string]$Database = "fxl_game_local",
    [string]$BaseSchema = "",
    [switch]$ImportData
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

$MysqlExe = "mysql"
if (-not (Get-Command mysql -ErrorAction SilentlyContinue)) {
    $knownMysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
    if (Test-Path $knownMysql) {
        $MysqlExe = $knownMysql
    } else {
        throw "mysql client not found. Install MySQL client/server first."
    }
}

if (-not $BaseSchema) {
    $roleInfoPattern = "CREATE\s+TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+``?role_info``?\s*\("
    $candidate = Get-ChildItem (Join-Path $Root "server\sql") -File |
        Where-Object { Select-String -Path $_.FullName -Pattern $roleInfoPattern -Quiet } |
        Select-Object -First 1
    if ($candidate) { $BaseSchema = $candidate.FullName }
}

if (-not $BaseSchema) {
    $generator = Join-Path $Root "tools\local\New-MinSchema.ps1"
    $fallback = Join-Path $Root "server\sql\local_min_schema.sql"
    if (-not (Test-Path $fallback)) {
        & pwsh -ExecutionPolicy Bypass -File $generator -OutFile $fallback
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    $BaseSchema = $fallback
    Write-Warning "Using generated fallback schema: $BaseSchema"
}

function Convert-MySqlPath($Path) {
    return ($Path -replace "\\", "/")
}

$createSql = "CREATE DATABASE IF NOT EXISTS ``$Database`` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
& $MysqlExe "-u$MySqlUser" "-p$MySqlPassword" "--default-character-set=utf8" "--execute=$createSql"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$schemaPath = Convert-MySqlPath $BaseSchema
& $MysqlExe "-u$MySqlUser" "-p$MySqlPassword" "--default-character-set=utf8" $Database "--execute=source $schemaPath"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($ImportData) {
    $dataFiles = @(
        @{ Path = "server\sql\_all_sql.sql"; Charset = "utf8" },
        @{ Path = "server\sql\item_template.sql"; Charset = "utf8" },
        @{ Path = "server\sql\huodong_sql.txt"; Charset = "gbk" },
        @{ Path = "server\sql\role_xiuxian.txt"; Charset = "gbk" }
    )
    foreach ($entry in $dataFiles) {
        $rel = $entry.Path
        $charset = $entry.Charset
        $file = Join-Path $Root $rel
        if (Test-Path $file) {
            Write-Host "Importing $file ($charset)"
            $mysqlPath = Convert-MySqlPath $file
            & $MysqlExe "-u$MySqlUser" "-p$MySqlPassword" "--default-character-set=$charset" $Database "--execute=source $mysqlPath"
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
    }
}

Write-Host "Database initialized: $Database"
