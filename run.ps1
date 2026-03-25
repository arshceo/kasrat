# run.ps1 — Pipes flutter run output through a noise filter.
# Usage: .\run.ps1
# Interactive commands (r, R, q) still work — stdin is passed through.

$noise = "Camera2PresenceSrc|OplusCameraManagerGlobal|OplusStatistics|" +
         "OplusCamera2StatisticsManager|Refreshed camera list|setClientInfo|" +
         "onCameraAccessPrioritiesChanged|BufferQueueProducer|BufferQueueConsumer|" +
         "DeferrableSurface|CameraStateRegistry|Camera2CameraImpl|" +
         "SyncCaptureSessionImpl|CaptureSession|CameraStateMachine|" +
         "UseCaseAttachState|Camera2CaptureRequestBuilder|VideoUsageControl|" +
         "ScreenFlashWrapper|ImageCapture|VRI\[MainActivity\]|" +
         "oplus\.statistics|com\.oplus"

Write-Host "[USTAD AI] Starting with ColorOS noise suppressed..." -ForegroundColor Red
Write-Host "[USTAD AI] Type r=hot reload, R=restart, q=quit" -ForegroundColor DarkGray
Write-Host ""

# Pipe flutter run stdout+stderr through the noise filter.
# stdin is inherited, so interactive commands still work.
flutter run 2>&1 | Where-Object { $_ -notmatch $noise }
