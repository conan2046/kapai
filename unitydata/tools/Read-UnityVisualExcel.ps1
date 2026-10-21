# Shared narrow reader for client visual tables. Row 1 is keys, rows 2..4 are
# export scope, descriptions and types; data begins at row 5.
function Read-UnityVisualExcelRows([string]$Path, [int]$SheetIndex = 1, [string]$SheetName, [switch]$RejectFormulas,
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
        if($ColumnMap) {
            foreach($column in $ColumnMap.Keys) {
                if($column -cnotmatch '^[A-Z]{1,3}$' -or [string]::IsNullOrWhiteSpace([string]$ColumnMap[$column]) -or $ColumnMap[$column] -in $headers.Values){throw 'Invalid Excel column map'}
                $headers[$column]=[string]$ColumnMap[$column]
            }
        } else {
            foreach ($cell in $rows[0].SelectNodes('s:c', $ns)) {
                $key = Read-VisualExcelCell $cell
                if ($RejectFormulas -and $key -and $key -in $headers.Values) { throw "Duplicate Excel column: $key" }
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
                    $record[$headers[$column]] = Read-VisualExcelCell $cell
                }
            }
            if ($record.Count -gt 0) { $record }
        }
    }
    finally { $archive.Dispose() }
}
