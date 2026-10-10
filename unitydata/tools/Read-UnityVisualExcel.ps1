# Shared narrow reader for client visual tables. Row 1 is keys, rows 2..4 are
# export scope, descriptions and types; data begins at row 5.
function Read-UnityVisualExcelRows([string]$Path) {
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
        $sheet = Read-VisualExcelPart 'xl/worksheets/sheet1.xml'
        $ns = [Xml.XmlNamespaceManager]::new($sheet.NameTable)
        $ns.AddNamespace('s', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
        function Read-VisualExcelCell($Cell) {
            if ($Cell.GetAttribute('t') -eq 's') { return $shared[[int]$Cell.v] }
            if ($Cell.GetAttribute('t') -eq 'inlineStr') { return $Cell.is.InnerText }
            return [string]$Cell.v
        }
        $headers = @{}
        $rows = @($sheet.SelectNodes('//s:sheetData/s:row', $ns))
        foreach ($cell in $rows[0].SelectNodes('s:c', $ns)) {
            $headers[[regex]::Match($cell.r,'^[A-Z]+').Value] = Read-VisualExcelCell $cell
        }
        foreach ($row in $rows) {
            if ([int]$row.r -lt 5) { continue }
            $record = [ordered]@{}
            foreach ($cell in $row.SelectNodes('s:c', $ns)) {
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
