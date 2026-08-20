param(
    [Parameter(Mandatory = $true)]
    [string]$SqliteReport,
    [Parameter(Mandatory = $true)]
    [string]$MySqlReport,
    [string]$ModuleManifest = "",
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Resolve-ProjectPath([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $Root $Path))
}

$SqliteReport = Resolve-ProjectPath $SqliteReport
$MySqlReport = Resolve-ProjectPath $MySqlReport
if (-not $ModuleManifest) {
    $ModuleManifest = Join-Path $Root "tools\unity-migration\unityclient-modules.json"
} else {
    $ModuleManifest = Resolve-ProjectPath $ModuleManifest
}
if (-not $OutFile) {
    $OutFile = Join-Path $Root ".local\unity-validation\steam-sqlite-s5-protocol-parity-latest.json"
} else {
    $OutFile = Resolve-ProjectPath $OutFile
}

$sqlite = Get-Content -LiteralPath $SqliteReport -Raw -Encoding UTF8 | ConvertFrom-Json
$mysql = Get-Content -LiteralPath $MySqlReport -Raw -Encoding UTF8 | ConvertFrom-Json
$manifest = Get-Content -LiteralPath $ModuleManifest -Raw -Encoding UTF8 | ConvertFrom-Json

if ($sqlite.status -ne "Passed" -or $mysql.status -ne "Passed") {
    throw "Both protocol reports must have status=Passed."
}
if (-not $sqlite.flags.steamIncluded -or -not $mysql.flags.steamIncluded) {
    throw "Both protocol reports must be generated with -SteamIncluded."
}

$sqliteCases = @($sqlite.sentCases)
$mysqlCases = @($mysql.sentCases)
$sentCasesEqual = ($sqliteCases.Count -eq $mysqlCases.Count) -and
    (($sqliteCases -join "`n") -ceq ($mysqlCases -join "`n"))

$includedModules = @($manifest.modules | Where-Object { -not $_.migrationExcluded })
$manifestProtocols = @(
    $includedModules |
        ForEach-Object {
            $steamProperty = $_.PSObject.Properties['steamProtocols']
            if ($steamProperty) { @($steamProperty.Value) } else { @($_.protocols) }
        } |
        ForEach-Object { [int]$_ } |
        Sort-Object -Unique
)
$allResponseTypes = @(
    @($sqlite.responseCountsByType.PSObject.Properties.Name) +
    @($mysql.responseCountsByType.PSObject.Properties.Name) +
    @($manifestProtocols | ForEach-Object { [string]$_ }) |
        Sort-Object { [int]$_ } -Unique
)

$rows = @(
    foreach ($typeText in $allResponseTypes) {
        $type = [int]$typeText
        $sqliteCountProperty = $sqlite.responseCountsByType.PSObject.Properties[$typeText]
        $mysqlCountProperty = $mysql.responseCountsByType.PSObject.Properties[$typeText]
        $sqliteCount = if ($sqliteCountProperty) { [int]$sqliteCountProperty.Value } else { 0 }
        $mysqlCount = if ($mysqlCountProperty) { [int]$mysqlCountProperty.Value } else { 0 }
        $sqliteLengthsProperty = $sqlite.responseBodyLengthsByType.PSObject.Properties[$typeText]
        $mysqlLengthsProperty = $mysql.responseBodyLengthsByType.PSObject.Properties[$typeText]
        $sqliteLengths = if ($sqliteLengthsProperty) { @($sqliteLengthsProperty.Value | ForEach-Object { [int]$_ }) } else { @() }
        $mysqlLengths = if ($mysqlLengthsProperty) { @($mysqlLengthsProperty.Value | ForEach-Object { [int]$_ }) } else { @() }
        $sqliteHashProperty = $sqlite.responseBodySha256ByType.PSObject.Properties[$typeText]
        $mysqlHashProperty = $mysql.responseBodySha256ByType.PSObject.Properties[$typeText]
        $sqliteHash = if ($sqliteHashProperty) { [string]$sqliteHashProperty.Value } else { "" }
        $mysqlHash = if ($mysqlHashProperty) { [string]$mysqlHashProperty.Value } else { "" }
        $modules = @(
            $includedModules |
                Where-Object {
                    $steamProperty = $_.PSObject.Properties['steamProtocols']
                    $effectiveProtocols = if ($steamProperty) { @($steamProperty.Value) } else { @($_.protocols) }
                    $effectiveProtocols -contains $type
                } |
                ForEach-Object { $_.key }
        )
        $presence = if ($sqliteCount -gt 0 -and $mysqlCount -gt 0) {
            "both"
        } elseif ($sqliteCount -eq 0 -and $mysqlCount -eq 0) {
            "missing-both"
        } elseif ($sqliteCount -gt 0) {
            "sqlite-only"
        } else {
            "mysql-only"
        }
        $countEqual = $sqliteCount -eq $mysqlCount
        $lengthsEqual = (($sqliteLengths -join ",") -ceq ($mysqlLengths -join ","))
        $hashEqual = $sqliteHash -and $mysqlHash -and ($sqliteHash -ceq $mysqlHash)
        $classification = if ($presence -in @("sqlite-only", "mysql-only")) {
            "backend-mismatch"
        } elseif ($presence -eq "missing-both") {
            "missing-both"
        } elseif ($countEqual -and $lengthsEqual -and $hashEqual) {
            "byte-match"
        } elseif ($countEqual -and $lengthsEqual) {
            "shape-match-content-dynamic"
        } else {
            "structural-difference"
        }
        [pscustomobject]@{
            protocol = $type
            manifestProtocol = $manifestProtocols -contains $type
            modules = $modules
            sqliteCount = $sqliteCount
            mysqlCount = $mysqlCount
            presence = $presence
            countEqual = $countEqual
            bodyLengthsEqual = $lengthsEqual
            bodySha256Equal = [bool]$hashEqual
            classification = $classification
        }
    }
)

$manifestRows = @($rows | Where-Object manifestProtocol)
$backendMismatches = @($manifestRows | Where-Object classification -eq "backend-mismatch")
$missingBoth = @($manifestRows | Where-Object classification -eq "missing-both")
$structuralDifferences = @($manifestRows | Where-Object classification -eq "structural-difference")
$bagParityRequested = [bool]$sqlite.flags.bagParity -or [bool]$mysql.flags.bagParity
$bagParity = $null
if ($bagParityRequested) {
    if (-not $sqlite.flags.bagParity -or -not $mysql.flags.bagParity) {
        throw "Bag parity must be enabled in both reports."
    }
    if ($sqlite.bagParity.status -ne "Passed" -or $mysql.bagParity.status -ne "Passed") {
        throw "Both Bag parity semantic reports must have status=Passed."
    }
    $sqliteBag = @($sqlite.bagParity.semanticCases | ForEach-Object {
        [ordered]@{ case = $_.case; packageUpdates = @($_.packageUpdates) }
    })
    $mysqlBag = @($mysql.bagParity.semanticCases | ForEach-Object {
        [ordered]@{ case = $_.case; packageUpdates = @($_.packageUpdates) }
    })
    $sqliteBagJson = $sqliteBag | ConvertTo-Json -Depth 8 -Compress
    $mysqlBagJson = $mysqlBag | ConvertTo-Json -Depth 8 -Compress
    $bagParity = [ordered]@{
        status = if ($sqliteBagJson -ceq $mysqlBagJson) { "Passed" } else { "Failed" }
        semanticCasesEqual = $sqliteBagJson -ceq $mysqlBagJson
        sqlite = $sqliteBag
        mysql = $mysqlBag
    }
}
$taskParityRequested = [bool]$sqlite.flags.taskParity -or [bool]$mysql.flags.taskParity -or [bool]$sqlite.flags.taskRestartVerify -or [bool]$mysql.flags.taskRestartVerify
$taskParity = $null
if ($taskParityRequested) {
    $sqliteTaskMode = if ($sqlite.flags.taskRestartVerify) { "restart" } elseif ($sqlite.flags.taskParity) { "runtime" } else { "none" }
    $mysqlTaskMode = if ($mysql.flags.taskRestartVerify) { "restart" } elseif ($mysql.flags.taskParity) { "runtime" } else { "none" }
    if ($sqliteTaskMode -eq "none" -or $sqliteTaskMode -ne $mysqlTaskMode) {
        throw "Task parity mode must match in both reports."
    }
    if ($sqlite.taskParity.status -ne "Passed" -or $mysql.taskParity.status -ne "Passed") {
        throw "Both Task parity semantic reports must have status=Passed."
    }
    $sqliteTask = @($sqlite.taskParity.semanticCases | ForEach-Object {
        [ordered]@{ case = $_.case; taskResponses = @($_.taskResponses) }
    })
    $mysqlTask = @($mysql.taskParity.semanticCases | ForEach-Object {
        [ordered]@{ case = $_.case; taskResponses = @($_.taskResponses) }
    })
    $sqliteTaskJson = $sqliteTask | ConvertTo-Json -Depth 12 -Compress
    $mysqlTaskJson = $mysqlTask | ConvertTo-Json -Depth 12 -Compress
    $taskParity = [ordered]@{
        status = if ($sqliteTaskJson -ceq $mysqlTaskJson) { "Passed" } else { "Failed" }
        mode = $sqliteTaskMode
        semanticCasesEqual = $sqliteTaskJson -ceq $mysqlTaskJson
        sqlite = $sqliteTask
        mysql = $mysqlTask
    }
}
$playerHudParityRequested = [bool]$sqlite.flags.playerHudParity -or [bool]$mysql.flags.playerHudParity
$playerHudParity = $null
if ($playerHudParityRequested) {
    if (-not $sqlite.flags.playerHudParity -or -not $mysql.flags.playerHudParity) {
        throw "PlayerHud parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.playerHudParity.status -ne "Passed" -or $mysql.playerHudParity.status -ne "Passed") {
        throw "Both PlayerHud parity reports must have status=Passed."
    }
    $sqlitePlayerHud = @($sqlite.playerHudParity.semanticCases | ForEach-Object {
        ConvertTo-Json $_ -Compress -Depth 20
    })
    $mysqlPlayerHud = @($mysql.playerHudParity.semanticCases | ForEach-Object {
        ConvertTo-Json $_ -Compress -Depth 20
    })
    $playerHudParity = [ordered]@{
        status = if (($sqlitePlayerHud -join "`n") -ceq ($mysqlPlayerHud -join "`n")) { "Passed" } else { "Failed" }
        semanticCasesEqual = (($sqlitePlayerHud -join "`n") -ceq ($mysqlPlayerHud -join "`n"))
        sqlite = @($sqlite.playerHudParity.semanticCases)
        mysql = @($mysql.playerHudParity.semanticCases)
    }
}
$heroParityRequested = [bool]$sqlite.flags.heroParity -or [bool]$mysql.flags.heroParity -or [bool]$sqlite.flags.heroRestartVerify -or [bool]$mysql.flags.heroRestartVerify
$heroParity = $null
if ($heroParityRequested) {
    $sqliteHeroMode = if ($sqlite.flags.heroRestartVerify) { "restart" } elseif ($sqlite.flags.heroParity) { "runtime" } else { "none" }
    $mysqlHeroMode = if ($mysql.flags.heroRestartVerify) { "restart" } elseif ($mysql.flags.heroParity) { "runtime" } else { "none" }
    if ($sqliteHeroMode -eq "none" -or $sqliteHeroMode -ne $mysqlHeroMode) {
        throw "Hero parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.heroParity.status -ne "Passed" -or $mysql.heroParity.status -ne "Passed") {
        throw "Both Hero parity reports must have status=Passed."
    }
    $sqliteHero = @($sqlite.heroParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 20 })
    $mysqlHero = @($mysql.heroParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 20 })
    $heroParity = [ordered]@{
        status = if (($sqliteHero -join "`n") -ceq ($mysqlHero -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteHeroMode
        semanticCasesEqual = (($sqliteHero -join "`n") -ceq ($mysqlHero -join "`n"))
        sqlite = @($sqlite.heroParity.semanticCases)
        mysql = @($mysql.heroParity.semanticCases)
    }
}
$heroEquipParityRequested = [bool]$sqlite.flags.heroEquipParity -or [bool]$mysql.flags.heroEquipParity -or [bool]$sqlite.flags.heroEquipRestartVerify -or [bool]$mysql.flags.heroEquipRestartVerify
$heroEquipParity = $null
if ($heroEquipParityRequested) {
    $sqliteHeroEquipMode = if ($sqlite.flags.heroEquipRestartVerify) { "restart" } elseif ($sqlite.flags.heroEquipParity) { "runtime" } else { "none" }
    $mysqlHeroEquipMode = if ($mysql.flags.heroEquipRestartVerify) { "restart" } elseif ($mysql.flags.heroEquipParity) { "runtime" } else { "none" }
    if ($sqliteHeroEquipMode -eq "none" -or $sqliteHeroEquipMode -ne $mysqlHeroEquipMode) {
        throw "HeroEquip parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.heroEquipParity.status -ne "Passed" -or $mysql.heroEquipParity.status -ne "Passed") {
        throw "Both HeroEquip parity reports must have status=Passed."
    }
    $sqliteHeroEquip = @($sqlite.heroEquipParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $mysqlHeroEquip = @($mysql.heroEquipParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $heroEquipParity = [ordered]@{
        status = if (($sqliteHeroEquip -join "`n") -ceq ($mysqlHeroEquip -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteHeroEquipMode
        semanticCasesEqual = (($sqliteHeroEquip -join "`n") -ceq ($mysqlHeroEquip -join "`n"))
        sqlite = @($sqlite.heroEquipParity.semanticCases)
        mysql = @($mysql.heroEquipParity.semanticCases)
    }
}
$mailParityRequested = [bool]$sqlite.flags.mailParity -or [bool]$mysql.flags.mailParity -or [bool]$sqlite.flags.mailRestartVerify -or [bool]$mysql.flags.mailRestartVerify
$mailParity = $null
if ($mailParityRequested) {
    $sqliteMailMode = if ($sqlite.flags.mailRestartVerify) { "restart" } elseif ($sqlite.flags.mailParity) { "runtime" } else { "none" }
    $mysqlMailMode = if ($mysql.flags.mailRestartVerify) { "restart" } elseif ($mysql.flags.mailParity) { "runtime" } else { "none" }
    if ($sqliteMailMode -eq "none" -or $sqliteMailMode -ne $mysqlMailMode) {
        throw "Mail parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.mailParity.status -ne "Passed" -or $mysql.mailParity.status -ne "Passed") {
        throw "Both Mail parity reports must have status=Passed."
    }
    $sqliteMail = @($sqlite.mailParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $mysqlMail = @($mysql.mailParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $mailParity = [ordered]@{
        status = if (($sqliteMail -join "`n") -ceq ($mysqlMail -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteMailMode
        semanticCasesEqual = (($sqliteMail -join "`n") -ceq ($mysqlMail -join "`n"))
        sqlite = @($sqlite.mailParity.semanticCases)
        mysql = @($mysql.mailParity.semanticCases)
    }
}
$shopParityRequested = [bool]$sqlite.flags.shopParity -or [bool]$mysql.flags.shopParity -or [bool]$sqlite.flags.shopRestartVerify -or [bool]$mysql.flags.shopRestartVerify
$shopParity = $null
if ($shopParityRequested) {
    $sqliteShopMode = if ($sqlite.flags.shopRestartVerify) { "restart" } elseif ($sqlite.flags.shopParity) { "runtime" } else { "none" }
    $mysqlShopMode = if ($mysql.flags.shopRestartVerify) { "restart" } elseif ($mysql.flags.shopParity) { "runtime" } else { "none" }
    if ($sqliteShopMode -eq "none" -or $sqliteShopMode -ne $mysqlShopMode) {
        throw "Shop parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.shopParity.status -ne "Passed" -or $mysql.shopParity.status -ne "Passed") {
        throw "Both Shop parity reports must have status=Passed."
    }
    $sqliteShop = @($sqlite.shopParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $mysqlShop = @($mysql.shopParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $shopParity = [ordered]@{
        status = if (($sqliteShop -join "`n") -ceq ($mysqlShop -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteShopMode
        semanticCasesEqual = (($sqliteShop -join "`n") -ceq ($mysqlShop -join "`n"))
        sqlite = @($sqlite.shopParity.semanticCases)
        mysql = @($mysql.shopParity.semanticCases)
    }
}
$gameplayShopsParityRequested = [bool]$sqlite.flags.gameplayShopsParity -or [bool]$mysql.flags.gameplayShopsParity -or [bool]$sqlite.flags.gameplayShopsRestartVerify -or [bool]$mysql.flags.gameplayShopsRestartVerify
$gameplayShopsParity = $null
if ($gameplayShopsParityRequested) {
    $sqliteGameplayShopsMode = if ($sqlite.flags.gameplayShopsRestartVerify) { "restart" } elseif ($sqlite.flags.gameplayShopsParity) { "runtime" } else { "none" }
    $mysqlGameplayShopsMode = if ($mysql.flags.gameplayShopsRestartVerify) { "restart" } elseif ($mysql.flags.gameplayShopsParity) { "runtime" } else { "none" }
    if ($sqliteGameplayShopsMode -eq "none" -or $sqliteGameplayShopsMode -ne $mysqlGameplayShopsMode) {
        throw "GameplayShops parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.gameplayShopsParity.status -ne "Passed" -or $mysql.gameplayShopsParity.status -ne "Passed") {
        throw "Both GameplayShops parity reports must have status=Passed."
    }
    $sqliteGameplayShops = @($sqlite.gameplayShopsParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $mysqlGameplayShops = @($mysql.gameplayShopsParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $gameplayShopsParity = [ordered]@{
        status = if (($sqliteGameplayShops -join "`n") -ceq ($mysqlGameplayShops -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteGameplayShopsMode
        semanticCasesEqual = (($sqliteGameplayShops -join "`n") -ceq ($mysqlGameplayShops -join "`n"))
        sqlite = @($sqlite.gameplayShopsParity.semanticCases)
        mysql = @($mysql.gameplayShopsParity.semanticCases)
    }
}
$worldParityRequested = [bool]$sqlite.flags.worldParity -or [bool]$mysql.flags.worldParity -or [bool]$sqlite.flags.worldRestartVerify -or [bool]$mysql.flags.worldRestartVerify
$worldParity = $null
if ($worldParityRequested) {
    $sqliteWorldMode = if ($sqlite.flags.worldRestartVerify) { "restart" } elseif ($sqlite.flags.worldParity) { "runtime" } else { "none" }
    $mysqlWorldMode = if ($mysql.flags.worldRestartVerify) { "restart" } elseif ($mysql.flags.worldParity) { "runtime" } else { "none" }
    if ($sqliteWorldMode -eq "none" -or $sqliteWorldMode -ne $mysqlWorldMode) {
        throw "World parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.worldParity.status -ne "Passed" -or $mysql.worldParity.status -ne "Passed") {
        throw "Both World parity reports must have status=Passed."
    }
    $sqliteWorld = @($sqlite.worldParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $mysqlWorld = @($mysql.worldParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $worldParity = [ordered]@{
        status = if (($sqliteWorld -join "`n") -ceq ($mysqlWorld -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteWorldMode
        semanticCasesEqual = (($sqliteWorld -join "`n") -ceq ($mysqlWorld -join "`n"))
        sqlite = @($sqlite.worldParity.semanticCases)
        mysql = @($mysql.worldParity.semanticCases)
    }
}
$drawParityRequested = [bool]$sqlite.flags.drawParity -or [bool]$mysql.flags.drawParity -or [bool]$sqlite.flags.drawRestartVerify -or [bool]$mysql.flags.drawRestartVerify
$drawParity = $null
if ($drawParityRequested) {
    $sqliteDrawMode = if ($sqlite.flags.drawRestartVerify) { "restart" } elseif ($sqlite.flags.drawParity) { "runtime" } else { "none" }
    $mysqlDrawMode = if ($mysql.flags.drawRestartVerify) { "restart" } elseif ($mysql.flags.drawParity) { "runtime" } else { "none" }
    if ($sqliteDrawMode -eq "none" -or $sqliteDrawMode -ne $mysqlDrawMode) {
        throw "Draw parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.drawParity.status -ne "Passed" -or $mysql.drawParity.status -ne "Passed") {
        throw "Both Draw parity reports must have status=Passed."
    }
    $sqliteDraw = @($sqlite.drawParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $mysqlDraw = @($mysql.drawParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 30 })
    $drawParity = [ordered]@{
        status = if (($sqliteDraw -join "`n") -ceq ($mysqlDraw -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteDrawMode
        semanticCasesEqual = (($sqliteDraw -join "`n") -ceq ($mysqlDraw -join "`n"))
        sqlite = @($sqlite.drawParity.semanticCases)
        mysql = @($mysql.drawParity.semanticCases)
    }
}
$gameplayParityRequested = [bool]$sqlite.flags.gameplayParity -or [bool]$mysql.flags.gameplayParity -or [bool]$sqlite.flags.gameplayRestartVerify -or [bool]$mysql.flags.gameplayRestartVerify
$gameplayParity = $null
if ($gameplayParityRequested) {
    $sqliteGameplayMode = if ($sqlite.flags.gameplayRestartVerify) { "restart" } elseif ($sqlite.flags.gameplayParity) { "runtime" } else { "none" }
    $mysqlGameplayMode = if ($mysql.flags.gameplayRestartVerify) { "restart" } elseif ($mysql.flags.gameplayParity) { "runtime" } else { "none" }
    if ($sqliteGameplayMode -eq "none" -or $sqliteGameplayMode -ne $mysqlGameplayMode) {
        throw "Gameplay parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.gameplayParity.status -ne "Passed" -or $mysql.gameplayParity.status -ne "Passed") {
        throw "Both Gameplay parity reports must have status=Passed."
    }
    $sqliteGameplay = @($sqlite.gameplayParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 12 })
    $mysqlGameplay = @($mysql.gameplayParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 12 })
    $gameplayParity = [ordered]@{
        status = if (($sqliteGameplay -join "`n") -ceq ($mysqlGameplay -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteGameplayMode
        semanticCasesEqual = (($sqliteGameplay -join "`n") -ceq ($mysqlGameplay -join "`n"))
        sqlite = @($sqlite.gameplayParity.semanticCases)
        mysql = @($mysql.gameplayParity.semanticCases)
    }
}
$youLiParityRequested = [bool]$sqlite.flags.youLiParity -or [bool]$mysql.flags.youLiParity -or [bool]$sqlite.flags.youLiRestartVerify -or [bool]$mysql.flags.youLiRestartVerify
$youLiParity = $null
if ($youLiParityRequested) {
    $sqliteYouLiMode = if ($sqlite.flags.youLiRestartVerify) { "restart" } elseif ($sqlite.flags.youLiParity) { "runtime" } else { "none" }
    $mysqlYouLiMode = if ($mysql.flags.youLiRestartVerify) { "restart" } elseif ($mysql.flags.youLiParity) { "runtime" } else { "none" }
    if ($sqliteYouLiMode -eq "none" -or $sqliteYouLiMode -ne $mysqlYouLiMode) {
        throw "YouLi parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.youLiParity.status -ne "Passed" -or $mysql.youLiParity.status -ne "Passed") {
        throw "Both YouLi parity reports must have status=Passed."
    }
    $sqliteYouLi = @($sqlite.youLiParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 12 })
    $mysqlYouLi = @($mysql.youLiParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 12 })
    $youLiParity = [ordered]@{
        status = if (($sqliteYouLi -join "`n") -ceq ($mysqlYouLi -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteYouLiMode
        semanticCasesEqual = (($sqliteYouLi -join "`n") -ceq ($mysqlYouLi -join "`n"))
        sqlite = @($sqlite.youLiParity.semanticCases)
        mysql = @($mysql.youLiParity.semanticCases)
    }
}
$fengShenStoryParityRequested = [bool]$sqlite.flags.fengShenStoryParity -or [bool]$mysql.flags.fengShenStoryParity -or [bool]$sqlite.flags.fengShenStoryRestartVerify -or [bool]$mysql.flags.fengShenStoryRestartVerify
$fengShenStoryParity = $null
if ($fengShenStoryParityRequested) {
    $sqliteFengShenStoryMode = if ($sqlite.flags.fengShenStoryRestartVerify) { "restart" } elseif ($sqlite.flags.fengShenStoryParity) { "runtime" } else { "none" }
    $mysqlFengShenStoryMode = if ($mysql.flags.fengShenStoryRestartVerify) { "restart" } elseif ($mysql.flags.fengShenStoryParity) { "runtime" } else { "none" }
    if ($sqliteFengShenStoryMode -eq "none" -or $sqliteFengShenStoryMode -ne $mysqlFengShenStoryMode) {
        throw "FengShenStory parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.fengShenStoryParity.status -ne "Passed" -or $mysql.fengShenStoryParity.status -ne "Passed") {
        throw "Both FengShenStory parity reports must have status=Passed."
    }
    $sqliteFengShenStory = @($sqlite.fengShenStoryParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 20 })
    $mysqlFengShenStory = @($mysql.fengShenStoryParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 20 })
    $fengShenStoryParity = [ordered]@{
        status = if (($sqliteFengShenStory -join "`n") -ceq ($mysqlFengShenStory -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteFengShenStoryMode
        semanticCasesEqual = (($sqliteFengShenStory -join "`n") -ceq ($mysqlFengShenStory -join "`n"))
        sqlite = @($sqlite.fengShenStoryParity.semanticCases)
        mysql = @($mysql.fengShenStoryParity.semanticCases)
    }
}
$arenaParityRequested = [bool]$sqlite.flags.arenaParity -or [bool]$mysql.flags.arenaParity -or [bool]$sqlite.flags.arenaRestartVerify -or [bool]$mysql.flags.arenaRestartVerify
$arenaParity = $null
if ($arenaParityRequested) {
    $sqliteArenaMode = if ($sqlite.flags.arenaRestartVerify) { "restart" } elseif ($sqlite.flags.arenaParity) { "runtime" } else { "none" }
    $mysqlArenaMode = if ($mysql.flags.arenaRestartVerify) { "restart" } elseif ($mysql.flags.arenaParity) { "runtime" } else { "none" }
    if ($sqliteArenaMode -eq "none" -or $sqliteArenaMode -ne $mysqlArenaMode) {
        throw "Arena parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.arenaParity.status -ne "Passed" -or $mysql.arenaParity.status -ne "Passed") {
        throw "Both Arena parity reports must have status=Passed."
    }
    $sqliteArena = @($sqlite.arenaParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 20 })
    $mysqlArena = @($mysql.arenaParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 20 })
    $arenaParity = [ordered]@{
        status = if (($sqliteArena -join "`n") -ceq ($mysqlArena -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteArenaMode
        semanticCasesEqual = (($sqliteArena -join "`n") -ceq ($mysqlArena -join "`n"))
        sqlite = @($sqlite.arenaParity.semanticCases)
        mysql = @($mysql.arenaParity.semanticCases)
    }
}
$xunBaoParityRequested = [bool]$sqlite.flags.xunBaoParity -or [bool]$mysql.flags.xunBaoParity -or [bool]$sqlite.flags.xunBaoRestartVerify -or [bool]$mysql.flags.xunBaoRestartVerify
$xunBaoParity = $null
if ($xunBaoParityRequested) {
    $sqliteXunBaoMode = if ($sqlite.flags.xunBaoRestartVerify) { "restart" } elseif ($sqlite.flags.xunBaoParity) { "runtime" } else { "none" }
    $mysqlXunBaoMode = if ($mysql.flags.xunBaoRestartVerify) { "restart" } elseif ($mysql.flags.xunBaoParity) { "runtime" } else { "none" }
    if ($sqliteXunBaoMode -eq "none" -or $sqliteXunBaoMode -ne $mysqlXunBaoMode) {
        throw "XunBao parity mode must match between SQLite and MySQL reports."
    }
    if ($sqlite.xunBaoParity.status -ne "Passed" -or $mysql.xunBaoParity.status -ne "Passed") {
        throw "Both XunBao parity reports must have status=Passed."
    }
    $sqliteXunBao = @($sqlite.xunBaoParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 12 })
    $mysqlXunBao = @($mysql.xunBaoParity.semanticCases | ForEach-Object { ConvertTo-Json $_ -Compress -Depth 12 })
    $xunBaoParity = [ordered]@{
        status = if (($sqliteXunBao -join "`n") -ceq ($mysqlXunBao -join "`n")) { "Passed" } else { "Failed" }
        mode = $sqliteXunBaoMode
        semanticCasesEqual = (($sqliteXunBao -join "`n") -ceq ($mysqlXunBao -join "`n"))
        sqlite = @($sqlite.xunBaoParity.semanticCases)
        mysql = @($mysql.xunBaoParity.semanticCases)
    }
}
$report = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    status = if ($sentCasesEqual -and $backendMismatches.Count -eq 0 -and (-not $bagParityRequested -or $bagParity.status -eq "Passed") -and (-not $taskParityRequested -or $taskParity.status -eq "Passed") -and (-not $playerHudParityRequested -or $playerHudParity.status -eq "Passed") -and (-not $heroParityRequested -or $heroParity.status -eq "Passed") -and (-not $heroEquipParityRequested -or $heroEquipParity.status -eq "Passed") -and (-not $mailParityRequested -or $mailParity.status -eq "Passed") -and (-not $shopParityRequested -or $shopParity.status -eq "Passed") -and (-not $gameplayShopsParityRequested -or $gameplayShopsParity.status -eq "Passed") -and (-not $worldParityRequested -or $worldParity.status -eq "Passed") -and (-not $drawParityRequested -or $drawParity.status -eq "Passed") -and (-not $gameplayParityRequested -or $gameplayParity.status -eq "Passed") -and (-not $youLiParityRequested -or $youLiParity.status -eq "Passed") -and (-not $fengShenStoryParityRequested -or $fengShenStoryParity.status -eq "Passed") -and (-not $arenaParityRequested -or $arenaParity.status -eq "Passed") -and (-not $xunBaoParityRequested -or $xunBaoParity.status -eq "Passed")) { "PassedWithDifferences" } else { "Failed" }
    sources = [ordered]@{
        sqlite = $SqliteReport
        mysql = $MySqlReport
        manifest = $ModuleManifest
    }
    sentCases = [ordered]@{
        equal = $sentCasesEqual
        sqliteCount = $sqliteCases.Count
        mysqlCount = $mysqlCases.Count
    }
    received = [ordered]@{
        sqliteCount = [int]$sqlite.receivedCount
        mysqlCount = [int]$mysql.receivedCount
    }
    manifest = [ordered]@{
        moduleCount = $includedModules.Count
        protocolCount = $manifestProtocols.Count
        backendMismatchCount = $backendMismatches.Count
        missingBothCount = $missingBoth.Count
        structuralDifferenceCount = $structuralDifferences.Count
    }
    moduleSemantics = [ordered]@{
        Bag = $bagParity
        Task = $taskParity
        PlayerHud = $playerHudParity
        Hero = $heroParity
        HeroEquip = $heroEquipParity
        Mail = $mailParity
        Shop = $shopParity
        GameplayShops = $gameplayShopsParity
        World = $worldParity
        Draw = $drawParity
        Gameplay = $gameplayParity
        YouLi = $youLiParity
        FengShenStory = $fengShenStoryParity
        Arena = $arenaParity
        XunBao = $xunBaoParity
    }
    protocols = $rows
}

$directory = Split-Path -Parent $OutFile
if ($directory) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
$report | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $OutFile -Encoding UTF8

Write-Host "Protocol parity report: $OutFile"
Write-Host "status=$($report.status) sent_cases_equal=$sentCasesEqual sqlite_received=$($sqlite.receivedCount) mysql_received=$($mysql.receivedCount) manifest_backend_mismatch=$($backendMismatches.Count) manifest_missing_both=$($missingBoth.Count) manifest_structural_difference=$($structuralDifferences.Count)"
if ($report.status -eq "Failed") { exit 1 }
