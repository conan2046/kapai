# Shared narrow reader for client visual tables. Row 1 is keys, rows 2..4 are
# export scope, descriptions and types; data begins at row 5.
function Read-UnityVisualExcelRows([string]$Path, [int]$SheetIndex = 1, [string]$SheetName, [switch]$RejectFormulas, [switch]$ResolveIntegerFormulas, [switch]$IgnoreCommentColumns,
    [hashtable]$ColumnMap, [ValidateRange(1,1048576)][int]$FirstDataRow = 5,
    [ValidateRange(1,1048576)][int]$LastDataRow = 1048576) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        function Read-VisualExcelPart([string]$Name) {
            $entry = $archive.GetEntry($Name)
            if ($null -eq $entry) { throw "Missing Excel part: $Name" }
            $reader = [IO.StreamReader]::new($entry.Open(), [Text.Encoding]::UTF8)
            try { return [xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
        }
        $shared = @()
        if ($archive.GetEntry('xl/sharedStrings.xml')) {
            $strings = Read-VisualExcelPart 'xl/sharedStrings.xml'
            $stringNs = [Xml.XmlNamespaceManager]::new($strings.NameTable)
            $stringNs.AddNamespace('s', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
            $shared = @($strings.SelectNodes('//s:si', $stringNs) | ForEach-Object { $_.InnerText })
        }
        if ($SheetIndex -lt 1) { throw 'Excel sheet index must be positive.' }
        $sheetPart = 'xl/worksheets/sheet{0}.xml' -f $SheetIndex
        if ($SheetName) {
            $workbook = Read-VisualExcelPart 'xl/workbook.xml'
            $workbookNs = [Xml.XmlNamespaceManager]::new($workbook.NameTable)
            $workbookNs.AddNamespace('s', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
            $matches = @($workbook.SelectNodes('//s:sheets/s:sheet', $workbookNs) | Where-Object { $_.name -ceq $SheetName })
            if ($matches.Count -ne 1) { throw "Missing/duplicate Excel sheet: $SheetName" }
            $id = $matches[0].GetAttribute('id','http://schemas.openxmlformats.org/officeDocument/2006/relationships')
            $relations = Read-VisualExcelPart 'xl/_rels/workbook.xml.rels'
            $relation = @($relations.Relationships.Relationship | Where-Object Id -eq $id)
            if ($relation.Count -ne 1) { throw "Missing Excel sheet relationship: $SheetName" }
            $target = [string]$relation[0].Target
            $sheetPart = if ($target.StartsWith('/')) { $target.TrimStart('/') } else { 'xl/' + $target }
        }
        $sheet = Read-VisualExcelPart $sheetPart
        $ns = [Xml.XmlNamespaceManager]::new($sheet.NameTable)
        $ns.AddNamespace('s', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
        function Read-VisualExcelCell($Cell) {
            if ($Cell.GetAttribute('t') -eq 's') { return $shared[[int]$Cell.v] }
            if ($Cell.GetAttribute('t') -eq 'inlineStr') { return $Cell.is.InnerText }
            return [string]$Cell.v
        }
        $headers = @{}
        $rows = @($sheet.SelectNodes('//s:sheetData/s:row', $ns))
        $cellIndex=@{}; $formulaBases=@{}; $resolvedValues=@{}
        foreach($sourceRow in $rows) { foreach($sourceCell in $sourceRow.SelectNodes('s:c',$ns)) {
            $cellIndex[[string]$sourceCell.r]=$sourceCell
            $f=$sourceCell.SelectSingleNode('s:f',$ns)
            if($f -and $f.InnerText -and $f.GetAttribute('t') -eq 'shared'){$formulaBases[$f.GetAttribute('si')]=@{cell=[string]$sourceCell.r;formula=$f.InnerText}}
        }}
        function Resolve-VisualInteger($Cell,[hashtable]$Trail) {
            $address=[string]$Cell.r
            if($resolvedValues.ContainsKey($address)){return $resolvedValues[$address]}
            if($Trail.ContainsKey($address)){throw "Circular Excel formula: $address"}
            $Trail[$address]=$true
            try {
                $f=$Cell.SelectSingleNode('s:f',$ns)
                if(-not $f){$value=Read-VisualExcelCell $Cell}
                else {
                    $formula=$f.InnerText
                    function Formula-Column([string]$Text){$n=0;foreach($c in $Text.ToCharArray()){$n=$n*26+[int]$c-64};return $n}
                    function Formula-Address([string]$Column,[string]$Row,[bool]$FixedColumn,[bool]$FixedRow,$Base) {
                        $c=Formula-Column $Column;$r=[int]$Row
                        if($Base) {
                            if(-not $FixedColumn){$c+=(Formula-Column ([regex]::Match($address,'^[A-Z]+').Value))-(Formula-Column ([regex]::Match($Base.cell,'^[A-Z]+').Value))}
                            if(-not $FixedRow){$r+=[int]([regex]::Match($address,'[0-9]+$').Value)-[int]([regex]::Match($Base.cell,'[0-9]+$').Value)}
                        }
                        if($c -lt 1 -or $c -gt 16384 -or $r -lt 1 -or $r -gt 1048576){throw "Excel formula outside sheet: $address"}
                        $letters='';while($c -gt 0){$c--; $letters=[char](65+$c%26)+$letters;$c=[math]::Floor($c/26)}
                        return $letters+$r
                    }
                    $base=$null
                    if(-not $formula) {
                        $base=$formulaBases[$f.GetAttribute('si')]
                        if(-not $base){throw "Missing shared formula base: $address"}
                        $formula=$base.formula
                    }
                    # Only local integer arithmetic and literal concatenation are accepted.
                    # Shared references are translated from the source formula, never its cache.
                    $pieces=[regex]::Split($formula,'&(?=(?:[^"]*"[^"]*")*[^"]*$)')
                    $result=[Collections.Generic.List[string]]::new()
                    foreach($piece in $pieces) {
                        $piece=$piece.Trim()
                        if($piece -match '^"(?:[^"]|"")*"$'){$result.Add($piece.Substring(1,$piece.Length-2).Replace('""','"'));continue}
                        $expression=[regex]::Replace($piece,'(\$?)([A-Z]+)(\$?)([0-9]+)',[Text.RegularExpressions.MatchEvaluator]{
                            param($m)
                            $reference=Formula-Address $m.Groups[2].Value $m.Groups[4].Value ($m.Groups[1].Value -ne '') ($m.Groups[3].Value -ne '') $base
                            if(-not $cellIndex.ContainsKey($reference)){throw "Excel formula references missing cell: $address"}
                            $rawValue=Resolve-VisualInteger $cellIndex[$reference] $Trail
                            if([string]$rawValue -notmatch '^-?[0-9]+$'){throw "Excel formula references non-integer: $address"}
                            return '('+[string]$rawValue+')'
                        })
                        if($expression -notmatch '^[0-9+\-*/() ]+$'){throw "Unsupported Excel formula: $address"}
                        try{$value=[decimal]([System.Data.DataTable]::new().Compute($expression,''))}
                        catch{throw "Invalid Excel integer formula: $address"}
                        if($value -ne [decimal]::Truncate($value) -or $value -lt [long]::MinValue -or $value -gt [long]::MaxValue){throw "Excel integer formula overflow/fraction: $address"}
                        $result.Add(([long]$value).ToString([Globalization.CultureInfo]::InvariantCulture))
                    }
                    $value=$result -join ''

                }
                $resolvedValues[$address]=$value
                return $value
            } finally {$Trail.Remove($address)}
        }

        if($ColumnMap) {
            foreach($column in $ColumnMap.Keys) {
                if($column -cnotmatch '^[A-Z]{1,3}$' -or [string]::IsNullOrWhiteSpace([string]$ColumnMap[$column]) -or $ColumnMap[$column] -in $headers.Values){throw 'Invalid Excel column map'}
                $headers[$column]=[string]$ColumnMap[$column]
            }
        } else {
            foreach ($cell in $rows[0].SelectNodes('s:c', $ns)) {
                $key = Read-VisualExcelCell $cell
                if ($IgnoreCommentColumns -and $key -eq 'comment') { continue }
                if (($RejectFormulas -or $ResolveIntegerFormulas) -and $key -and $key -in $headers.Values) { throw "Duplicate Excel column: $key" }
                $headers[[regex]::Match($cell.r,'^[A-Z]+').Value] = $key
            }
        }
        foreach ($row in $rows) {
            if ([int]$row.r -lt $FirstDataRow -or [int]$row.r -gt $LastDataRow) { continue }
            $record = [ordered]@{}
            foreach ($cell in $row.SelectNodes('s:c', $ns)) {
                if ($RejectFormulas -and $cell.SelectSingleNode('s:f',$ns)) { throw "Formula cache is not a Unity source value: $SheetName $($cell.r)" }
                $column = [regex]::Match($cell.r,'^[A-Z]+').Value
                if ($headers.ContainsKey($column) -and $headers[$column]) {
                    $record[$headers[$column]] = if($ResolveIntegerFormulas -and $cell.SelectSingleNode('s:f',$ns)){Resolve-VisualInteger $cell @{}}else{Read-VisualExcelCell $cell}
                }
            }
            if ($record.Count -gt 0) { $record }
        }
    }
    finally { $archive.Dispose() }
}
