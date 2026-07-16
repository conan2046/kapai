param(
    [Nullable[int]]$ClickX = $null,
    [Nullable[int]]$ClickY = $null,
    [string]$CapturePath = "",
    [int]$WaitMilliseconds = 1000
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class CodexClientWindow {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint flags);
}
'@
Add-Type -AssemblyName System.Drawing

$process = Get-Process ProjectX -ErrorAction Stop | Select-Object -First 1
$process.Refresh()
if ($process.MainWindowHandle -eq [IntPtr]::Zero) {
    throw "ProjectX has no main window handle"
}

$foregroundBefore = [CodexClientWindow]::GetForegroundWindow()
if ($ClickX.HasValue -or $ClickY.HasValue) {
    if (-not $ClickX.HasValue -or -not $ClickY.HasValue) {
        throw "Pass both -ClickX and -ClickY as game-window client coordinates"
    }
    if ($ClickX.Value -lt 0 -or $ClickY.Value -lt 0) {
        throw "Click coordinates must be non-negative"
    }

    $lParam = [IntPtr](($ClickY.Value -shl 16) -bor ($ClickX.Value -band 0xFFFF))
    # Cocos ignores most main-screen touches while its Win32 window is marked
    # inactive. These messages update only the game's logical window state;
    # they do not call SetForegroundWindow or move the real cursor.
    [CodexClientWindow]::PostMessage($process.MainWindowHandle, 0x001C, [IntPtr]1, [IntPtr]::Zero) | Out-Null
    [CodexClientWindow]::PostMessage($process.MainWindowHandle, 0x0006, [IntPtr]1, [IntPtr]::Zero) | Out-Null
    [CodexClientWindow]::PostMessage($process.MainWindowHandle, 0x0007, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    [CodexClientWindow]::PostMessage($process.MainWindowHandle, 0x0200, [IntPtr]::Zero, $lParam) | Out-Null
    [CodexClientWindow]::PostMessage($process.MainWindowHandle, 0x0201, [IntPtr]1, $lParam) | Out-Null
    [CodexClientWindow]::PostMessage($process.MainWindowHandle, 0x0202, [IntPtr]::Zero, $lParam) | Out-Null
}

if ($WaitMilliseconds -gt 0) {
    Start-Sleep -Milliseconds $WaitMilliseconds
}

$rect = New-Object CodexClientWindow+RECT
if (-not [CodexClientWindow]::GetWindowRect($process.MainWindowHandle, [ref]$rect)) {
    throw "GetWindowRect failed"
}

if (-not $CapturePath) {
    $CapturePath = Join-Path $Root ".local\client-window.png"
}
elseif (-not [System.IO.Path]::IsPathRooted($CapturePath)) {
    $CapturePath = Join-Path $Root $CapturePath
}
$captureDir = Split-Path -Parent $CapturePath
if (-not (Test-Path $captureDir)) {
    New-Item -ItemType Directory -Force -Path $captureDir | Out-Null
}

$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
$bitmap = New-Object System.Drawing.Bitmap $width,$height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$hdc = $graphics.GetHdc()
try {
    $captured = [CodexClientWindow]::PrintWindow($process.MainWindowHandle, $hdc, 2)
}
finally {
    $graphics.ReleaseHdc($hdc)
    $graphics.Dispose()
}
if (-not $captured) {
    $bitmap.Dispose()
    throw "PrintWindow failed"
}
$bitmap.Save($CapturePath, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()

$foregroundAfter = [CodexClientWindow]::GetForegroundWindow()
[pscustomobject]@{
    Handle = $process.MainWindowHandle
    ClickX = $ClickX
    ClickY = $ClickY
    Width = $width
    Height = $height
    FocusUnchanged = ($foregroundBefore -eq $foregroundAfter)
    CapturePath = $CapturePath
}
