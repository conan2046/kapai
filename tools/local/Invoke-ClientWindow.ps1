param(
    [Nullable[int]]$ClickX = $null,
    [Nullable[int]]$ClickY = $null,
    [Nullable[int]]$DragFromX = $null,
    [Nullable[int]]$DragFromY = $null,
    [Nullable[int]]$DragToX = $null,
    [Nullable[int]]$DragToY = $null,
    [ValidateRange(2, 120)]
    [int]$DragSteps = 30,
    [ValidateRange(100, 5000)]
    [int]$DragDurationMilliseconds = 900,
    [Nullable[int]]$WheelX = $null,
    [Nullable[int]]$WheelY = $null,
    [int]$WheelDelta = 0,
    [string]$CapturePath = "",
    [switch]$RestoreNoActivate,
    [switch]$ActivateForeground,
    [switch]$RestoreForegroundAfter,
    [switch]$RealClick,
    [switch]$MessageDrag,
    [switch]$SkipCapture,
    [switch]$LogicalActivate,
    [switch]$LogicalDeactivateAfter,
    [switch]$CaptureClientOnly,
    [int]$NormalizeWidth = 0,
    [int]$NormalizeHeight = 0,
    [ValidateSet(0, 1, 2, 3)]
    [int]$PrintWindowFlags = 0,
    [int]$WaitMilliseconds = 1000
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class CodexClientWindow {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maxCount);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT point);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr SetActiveWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool attach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint flags);

    public static void ClickScreen(int x, int y) {
        SetCursorPos(x, y);
        mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(200);
        mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(150);
    }

    public static void DragScreen(int fromX, int fromY, int toX, int toY, int steps, int durationMilliseconds) {
        SetCursorPos(fromX, fromY);
        System.Threading.Thread.Sleep(100);
        mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero);
        int delay = Math.Max(1, durationMilliseconds / steps);
        for (int i = 1; i <= steps; ++i) {
            int x = fromX + ((toX - fromX) * i / steps);
            int y = fromY + ((toY - fromY) * i / steps);
            SetCursorPos(x, y);
            System.Threading.Thread.Sleep(delay);
        }
        mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero);
        System.Threading.Thread.Sleep(150);
    }

    private static IntPtr MouseLParam(int x, int y) {
        return new IntPtr((y << 16) | (x & 0xFFFF));
    }

    public static void DragClientMessages(IntPtr hWnd, int fromX, int fromY, int toX, int toY, int steps, int durationMilliseconds) {
        SendMessage(hWnd, 0x0200, IntPtr.Zero, MouseLParam(fromX, fromY));
        SendMessage(hWnd, 0x0201, new IntPtr(1), MouseLParam(fromX, fromY));
        int delay = Math.Max(1, durationMilliseconds / steps);
        for (int i = 1; i <= steps; ++i) {
            int x = fromX + ((toX - fromX) * i / steps);
            int y = fromY + ((toY - fromY) * i / steps);
            SendMessage(hWnd, 0x0200, new IntPtr(1), MouseLParam(x, y));
            System.Threading.Thread.Sleep(delay);
        }
        SendMessage(hWnd, 0x0202, IntPtr.Zero, MouseLParam(toX, toY));
        System.Threading.Thread.Sleep(150);
    }

    public static void WheelScreen(int x, int y, int delta) {
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(100);
        mouse_event(0x0800, 0, 0, unchecked((uint)delta), UIntPtr.Zero);
        System.Threading.Thread.Sleep(150);
    }

    public static bool ActivateWindow(IntPtr hWnd) {
        IntPtr foreground = GetForegroundWindow();
        uint ignored;
        uint currentThread = GetCurrentThreadId();
        uint targetThread = GetWindowThreadProcessId(hWnd, out ignored);
        uint foregroundThread = foreground == IntPtr.Zero ? 0 : GetWindowThreadProcessId(foreground, out ignored);
        bool attachedTarget = false;
        bool attachedForeground = false;
        try {
            if (targetThread != 0 && targetThread != currentThread) {
                attachedTarget = AttachThreadInput(currentThread, targetThread, true);
            }
            if (foregroundThread != 0 && foregroundThread != currentThread && foregroundThread != targetThread) {
                attachedForeground = AttachThreadInput(currentThread, foregroundThread, true);
            }
            ShowWindow(hWnd, 9);
            BringWindowToTop(hWnd);
            SetForegroundWindow(hWnd);
            SetActiveWindow(hWnd);
            SetFocus(hWnd);
            System.Threading.Thread.Sleep(150);
            return GetForegroundWindow() == hWnd;
        }
        finally {
            if (attachedForeground) AttachThreadInput(currentThread, foregroundThread, false);
            if (attachedTarget) AttachThreadInput(currentThread, targetThread, false);
        }
    }

    public static IntPtr FindGameWindow(int processId) {
        IntPtr best = IntPtr.Zero;
        long bestScore = -1;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            uint owner;
            GetWindowThreadProcessId(hWnd, out owner);
            if (owner != (uint)processId) return true;
            RECT rect;
            if (!GetWindowRect(hWnd, out rect)) return true;
            long width = Math.Max(0, rect.Right - rect.Left);
            long height = Math.Max(0, rect.Bottom - rect.Top);
            long area = width * height;
            StringBuilder title = new StringBuilder(512);
            GetWindowText(hWnd, title, title.Capacity);
            long score = area;
            if (title.ToString().IndexOf("Cocos Simulator", StringComparison.OrdinalIgnoreCase) >= 0) {
                score += 1000000000000L;
            }
            if (score > bestScore) { best = hWnd; bestScore = score; }
            return true;
        }, IntPtr.Zero);
        return best;
    }
}
'@
Add-Type -AssemblyName System.Drawing

$process = Get-Process ProjectX -ErrorAction Stop | Select-Object -First 1
$process.Refresh()
$windowHandle = [CodexClientWindow]::FindGameWindow($process.Id)
if ($windowHandle -eq [IntPtr]::Zero) {
    $windowHandle = $process.MainWindowHandle
}
if ($windowHandle -eq [IntPtr]::Zero) {
    throw "ProjectX has no visible top-level window handle"
}

$foregroundBefore = [CodexClientWindow]::GetForegroundWindow()
$activationSucceeded = $false
if ($RestoreNoActivate) {
    # SW_SHOWNOACTIVATE restores a minimized window without assigning focus.
    [CodexClientWindow]::ShowWindow($windowHandle, 4) | Out-Null
}
if ($ActivateForeground) {
    # A background pwsh process cannot assume SetForegroundWindow succeeded.
    # Attach input queues, focus the exact ProjectX window, and fail closed
    # before sending any real cursor input when activation is denied.
    $activationSucceeded = [CodexClientWindow]::ActivateWindow($windowHandle)
    if (-not $activationSucceeded) {
        throw "ProjectX did not become the foreground window; input was not sent"
    }
}
if ($ClickX.HasValue -or $ClickY.HasValue) {
    if (-not $ClickX.HasValue -or -not $ClickY.HasValue) {
        throw "Pass both -ClickX and -ClickY as game-window client coordinates"
    }
    if ($ClickX.Value -lt 0 -or $ClickY.Value -lt 0) {
        throw "Click coordinates must be non-negative"
    }

    if ($RealClick -and -not $ActivateForeground) {
        throw "-RealClick requires -ActivateForeground"
    }

    $lParam = [IntPtr](($ClickY.Value -shl 16) -bor ($ClickX.Value -band 0xFFFF))
    if ($RealClick) {
        $originalCursor = New-Object CodexClientWindow+POINT
        $screenPoint = New-Object CodexClientWindow+POINT
        $screenPoint.X = $ClickX.Value
        $screenPoint.Y = $ClickY.Value
        if (-not [CodexClientWindow]::ClientToScreen($windowHandle, [ref]$screenPoint)) {
            throw "ClientToScreen failed"
        }
        [CodexClientWindow]::GetCursorPos([ref]$originalCursor) | Out-Null
        [CodexClientWindow]::ClickScreen($screenPoint.X, $screenPoint.Y)
        [CodexClientWindow]::SetCursorPos($originalCursor.X, $originalCursor.Y) | Out-Null
    }
    elseif ($LogicalActivate) {
        # Some Cocos controls ignore background touches. This updates only the
        # game's logical state; it does not call SetForegroundWindow. Keep it
        # opt-in because inactive hardware-rendered surfaces may stop repainting.
        [CodexClientWindow]::PostMessage($windowHandle, 0x001C, [IntPtr]1, [IntPtr]::Zero) | Out-Null
        [CodexClientWindow]::PostMessage($windowHandle, 0x0006, [IntPtr]1, [IntPtr]::Zero) | Out-Null
        [CodexClientWindow]::PostMessage($windowHandle, 0x0007, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        [CodexClientWindow]::PostMessage($windowHandle, 0x0200, [IntPtr]::Zero, $lParam) | Out-Null
        [CodexClientWindow]::PostMessage($windowHandle, 0x0201, [IntPtr]1, $lParam) | Out-Null
        [CodexClientWindow]::PostMessage($windowHandle, 0x0202, [IntPtr]::Zero, $lParam) | Out-Null
        if ($LogicalDeactivateAfter) {
            [CodexClientWindow]::PostMessage($windowHandle, 0x0008, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
            [CodexClientWindow]::PostMessage($windowHandle, 0x0006, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
            [CodexClientWindow]::PostMessage($windowHandle, 0x001C, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        }
    }
    else {
        if ($ActivateForeground) {
            # GLFW consumes synchronous foreground mouse messages reliably;
            # queued PostMessage clicks may remain unhandled by this simulator.
            [CodexClientWindow]::SendMessage($windowHandle, 0x0200, [IntPtr]::Zero, $lParam) | Out-Null
            [CodexClientWindow]::SendMessage($windowHandle, 0x0201, [IntPtr]1, $lParam) | Out-Null
            Start-Sleep -Milliseconds 200
            [CodexClientWindow]::SendMessage($windowHandle, 0x0202, [IntPtr]::Zero, $lParam) | Out-Null
        }
        else {
            [CodexClientWindow]::PostMessage($windowHandle, 0x0200, [IntPtr]::Zero, $lParam) | Out-Null
            [CodexClientWindow]::PostMessage($windowHandle, 0x0201, [IntPtr]1, $lParam) | Out-Null
            [CodexClientWindow]::PostMessage($windowHandle, 0x0202, [IntPtr]::Zero, $lParam) | Out-Null
        }
    }
}

$dragCoordinates = @($DragFromX, $DragFromY, $DragToX, $DragToY)
$dragCoordinateCount = @($dragCoordinates | Where-Object { $_.HasValue }).Count
if ($dragCoordinateCount -ne 0) {
    if ($dragCoordinateCount -ne 4) {
        throw "Pass DragFromX, DragFromY, DragToX and DragToY together"
    }
    if (-not $ActivateForeground) {
        throw "Real drag requires -ActivateForeground"
    }
    if (@($dragCoordinates | Where-Object { $_.Value -lt 0 }).Count -gt 0) {
        throw "Drag coordinates must be non-negative"
    }
    if ($MessageDrag) {
        [CodexClientWindow]::DragClientMessages(
            $windowHandle,
            $DragFromX.Value,
            $DragFromY.Value,
            $DragToX.Value,
            $DragToY.Value,
            $DragSteps,
            $DragDurationMilliseconds
        )
    }
    else {
        $dragFromScreen = New-Object CodexClientWindow+POINT
        $dragFromScreen.X = $DragFromX.Value
        $dragFromScreen.Y = $DragFromY.Value
        $dragToScreen = New-Object CodexClientWindow+POINT
        $dragToScreen.X = $DragToX.Value
        $dragToScreen.Y = $DragToY.Value
        if (-not [CodexClientWindow]::ClientToScreen($windowHandle, [ref]$dragFromScreen) -or
            -not [CodexClientWindow]::ClientToScreen($windowHandle, [ref]$dragToScreen)) {
            throw "ClientToScreen failed for drag coordinates"
        }
        $originalCursor = New-Object CodexClientWindow+POINT
        [CodexClientWindow]::GetCursorPos([ref]$originalCursor) | Out-Null
        [CodexClientWindow]::DragScreen(
            $dragFromScreen.X,
            $dragFromScreen.Y,
            $dragToScreen.X,
            $dragToScreen.Y,
            $DragSteps,
            $DragDurationMilliseconds
        )
        [CodexClientWindow]::SetCursorPos($originalCursor.X, $originalCursor.Y) | Out-Null
    }
}

$wheelCoordinates = @($WheelX, $WheelY)
$wheelCoordinateCount = @(
    "WheelX", "WheelY" | Where-Object { $PSBoundParameters.ContainsKey($_) }
).Count
if ($WheelDelta -ne 0 -or $wheelCoordinateCount -ne 0) {
    if ($WheelDelta -eq 0 -or $wheelCoordinateCount -ne 2) {
        throw "Pass WheelX, WheelY and non-zero WheelDelta together"
    }
    if (-not $ActivateForeground) {
        throw "Mouse wheel injection requires -ActivateForeground"
    }
    if ([int]$WheelX -lt 0 -or [int]$WheelY -lt 0) {
        throw "Wheel coordinates must be non-negative"
    }
    $wheelScreen = New-Object CodexClientWindow+POINT
    $wheelScreen.X = [int]$WheelX
    $wheelScreen.Y = [int]$WheelY
    if (-not [CodexClientWindow]::ClientToScreen($windowHandle, [ref]$wheelScreen)) {
        throw "ClientToScreen failed for wheel coordinates"
    }
    $originalCursor = New-Object CodexClientWindow+POINT
    [CodexClientWindow]::GetCursorPos([ref]$originalCursor) | Out-Null
    [CodexClientWindow]::WheelScreen($wheelScreen.X, $wheelScreen.Y, $WheelDelta)
    [CodexClientWindow]::SetCursorPos($originalCursor.X, $originalCursor.Y) | Out-Null
}

if ($WaitMilliseconds -gt 0) {
    Start-Sleep -Milliseconds $WaitMilliseconds
}

$foregroundRestored = $false
if ($RestoreForegroundAfter -and $foregroundBefore -ne [IntPtr]::Zero -and $foregroundBefore -ne $windowHandle) {
    # Hardware-rendered Cocos surfaces are captured more reliably after focus
    # returns to the user's original window.
    $foregroundRestored = [CodexClientWindow]::SetForegroundWindow($foregroundBefore)
    Start-Sleep -Milliseconds 1500
}

$width = $null
$height = $null
$clientWidth = $null
$clientHeight = $null
if (-not $SkipCapture) {
    $rect = New-Object CodexClientWindow+RECT
    if (-not [CodexClientWindow]::GetWindowRect($windowHandle, [ref]$rect)) {
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

    $captureWidth = $rect.Right - $rect.Left
    $captureHeight = $rect.Bottom - $rect.Top
    $effectivePrintWindowFlags = [uint32]$PrintWindowFlags
    if ($CaptureClientOnly) {
        $clientRect = New-Object CodexClientWindow+RECT
        if (-not [CodexClientWindow]::GetClientRect($windowHandle, [ref]$clientRect)) {
            throw "GetClientRect failed"
        }
        $clientWidth = $clientRect.Right - $clientRect.Left
        $clientHeight = $clientRect.Bottom - $clientRect.Top
        $captureWidth = $clientWidth
        $captureHeight = $clientHeight
        $effectivePrintWindowFlags = $effectivePrintWindowFlags -bor 1
    }
    $bitmap = New-Object System.Drawing.Bitmap $captureWidth,$captureHeight
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $hdc = $graphics.GetHdc()
    try {
        $captured = [CodexClientWindow]::PrintWindow($windowHandle, $hdc, $effectivePrintWindowFlags)
    }
    finally {
        $graphics.ReleaseHdc($hdc)
        $graphics.Dispose()
    }
    if (-not $captured) {
        $bitmap.Dispose()
        throw "PrintWindow failed"
    }

    $outputBitmap = $bitmap

    if (($NormalizeWidth -gt 0) -xor ($NormalizeHeight -gt 0)) {
        $outputBitmap.Dispose()
        throw "Pass both -NormalizeWidth and -NormalizeHeight, or neither"
    }
    if ($NormalizeWidth -gt 0 -and $NormalizeHeight -gt 0) {
        $normalized = New-Object System.Drawing.Bitmap $NormalizeWidth,$NormalizeHeight
        $normalized.SetResolution($outputBitmap.HorizontalResolution, $outputBitmap.VerticalResolution)
        $normalizedGraphics = [System.Drawing.Graphics]::FromImage($normalized)
        try {
            $normalizedGraphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $normalizedGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $normalizedGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $normalizedGraphics.DrawImage($outputBitmap, 0, 0, $NormalizeWidth, $NormalizeHeight)
        }
        finally {
            $normalizedGraphics.Dispose()
            $outputBitmap.Dispose()
        }
        $outputBitmap = $normalized
    }

    $width = $outputBitmap.Width
    $height = $outputBitmap.Height
    $outputBitmap.Save($CapturePath, [System.Drawing.Imaging.ImageFormat]::Png)
    $outputBitmap.Dispose()
}

$foregroundAfter = [CodexClientWindow]::GetForegroundWindow()
[pscustomobject]@{
    Handle = $windowHandle
    ClickX = $ClickX
    ClickY = $ClickY
    DragFromX = $DragFromX
    DragFromY = $DragFromY
    DragToX = $DragToX
    DragToY = $DragToY
    WheelX = $WheelX
    WheelY = $WheelY
    WheelDelta = $WheelDelta
    Width = $width
    Height = $height
    ClientWidth = $clientWidth
    ClientHeight = $clientHeight
    ForegroundActivated = $ActivateForeground.IsPresent
    ActivationSucceeded = $activationSucceeded
    ForegroundRestored = $foregroundRestored
    RealClick = $RealClick.IsPresent
    MessageDrag = $MessageDrag.IsPresent
    FocusUnchanged = ($foregroundBefore -eq $foregroundAfter)
    PrintWindowFlags = $PrintWindowFlags
    CapturePath = $CapturePath
}
