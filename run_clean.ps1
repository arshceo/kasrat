# run_clean.ps1
# Run flutter with logcat noise filtered out.
# Suppresses ColorOS Camera2PresenceSrc spam that appears on Oppo/Realme/OnePlus devices.
#
# Usage: .\run_clean.ps1
#   or with a specific device: .\run_clean.ps1 -device <device_id>

param([string]$device = "")

# Kill any existing adb logcat processes
Get-Process -Name "adb" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*logcat*" } | Stop-Process -Force -ErrorAction SilentlyContinue

# Start flutter run in background
Write-Host "Starting flutter run..." -ForegroundColor Cyan
$flutterArgs = @("run")
if ($device -ne "") { $flutterArgs += @("-d", $device) }

$flutter = Start-Process -FilePath "flutter" -ArgumentList $flutterArgs -PassThru -NoNewWindow
Start-Sleep -Seconds 8

# Get app PID via adb
$pid_raw = adb shell "pidof com.ustadai.kasrat_ai" 2>$null
$appPid = ($pid_raw -split '\s+')[0].Trim()

if ($appPid -ne "") {
    Write-Host "App PID: $appPid — Starting filtered logcat..." -ForegroundColor Green
    # Filter OUT the noisy ColorOS tags completely
    adb logcat --pid=$appPid 2>$null | Where-Object {
        $_ -notmatch "Camera2PresenceSrc|OplusCameraManagerGlobal|OplusStatistics|com\.oplus\.statistics|onCameraAccessPrioritiesChanged|Refreshed camera list|setClientInfo"
    }
} else {
    Write-Host "Could not find app PID. Running unfiltered flutter run instead." -ForegroundColor Yellow
    Wait-Process -InputObject $flutter
}
