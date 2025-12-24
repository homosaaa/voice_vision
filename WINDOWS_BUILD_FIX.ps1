# ============================================================================
# FLUTTER WINDOWS BUILD CLEANUP & STABILIZATION SCRIPT
# ============================================================================
# Purpose: Clean Gradle cache corruption and file locks on Windows
# Usage: Run as Administrator: powershell -ExecutionPolicy Bypass -File WINDOWS_BUILD_FIX.ps1
# ============================================================================

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  FLUTTER WINDOWS BUILD - COMPLETE CLEANUP & FIX               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verify running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: This script should be run as Administrator for best results." -ForegroundColor Yellow
    Write-Host "   Rerun with: powershell -ExecutionPolicy Bypass -File WINDOWS_BUILD_FIX.ps1" -ForegroundColor Yellow
    Write-Host ""
}

# Navigate to project root
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot
Write-Host "📁 Project Root: $projectRoot" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PHASE 1: KILL ALL GRADLE & DART PROCESSES
# ============================================================================
Write-Host "PHASE 1: Killing Gradle, Dart, and Java Processes..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Yellow

$processNames = @("gradle", "dart", "java", "kotlin", "kotlinc")
foreach ($name in $processNames) {
    $processes = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "  ⚡ Killing $($name)..." -ForegroundColor Cyan
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "  ⏳ Waiting for file handles to release..." -ForegroundColor Cyan
[System.GC]::Collect()
Start-Sleep -Seconds 3
Write-Host "  ✅ Processes killed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# PHASE 2: DELETE BUILD ARTIFACTS (ORDER MATTERS!)
# ============================================================================
Write-Host "PHASE 2: Removing Stale Build Artifacts..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Yellow

$itemsToDelete = @(
    @{ Path = "build"; Description = "Flutter build output" },
    @{ Path = "android\build"; Description = "Android build output" },
    @{ Path = "android\.gradle"; Description = "Gradle local cache" },
    @{ Path = "android\app\build"; Description = "App build output" },
    @{ Path = "pubspec.lock"; Description = "Lock file (allows fresh dependencies)" }
)

foreach ($item in $itemsToDelete) {
    $fullPath = Join-Path $projectRoot $item.Path
    if (Test-Path $fullPath) {
        Write-Host "  🗑️  Removing: $($item.Description)" -ForegroundColor Cyan
        Write-Host "     Path: $($item.Path)" -ForegroundColor DarkGray
        try {
            if ((Get-Item $fullPath).PSIsContainer) {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
            } else {
                Remove-Item -Path $fullPath -Force -ErrorAction Stop
            }
            Write-Host "     ✅ Deleted" -ForegroundColor Green
        } catch {
            Write-Host "     ⚠️  Failed to delete (may require manual cleanup): $_" -ForegroundColor Yellow
        }
        Start-Sleep -Seconds 1
    } else {
        Write-Host "  ⏭️  Skipping (not found): $($item.Path)" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ============================================================================
# PHASE 3: FLUTTER CLEAN
# ============================================================================
Write-Host "PHASE 3: Flutter Clean..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "  🔧 Running: flutter clean" -ForegroundColor Cyan

try {
    flutter clean
    Write-Host "  ✅ Flutter clean completed" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Flutter clean error (non-critical): $_" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# PHASE 4: FRESH DEPENDENCY RESOLUTION
# ============================================================================
Write-Host "PHASE 4: Fresh Dependency Resolution..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "  📦 Running: flutter pub get" -ForegroundColor Cyan

try {
    flutter pub get
    Write-Host "  ✅ Dependencies resolved" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed to resolve dependencies: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ============================================================================
# PHASE 5: VERIFY CONFIGURATION
# ============================================================================
Write-Host "PHASE 5: Verifying Configuration..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Yellow

$gradlePropsPath = "android\gradle.properties"
if (Test-Path $gradlePropsPath) {
    Write-Host "  ✅ gradle.properties exists" -ForegroundColor Green
    $daemonDisabled = Select-String -Path $gradlePropsPath -Pattern "org.gradle.daemon=false" -ErrorAction SilentlyContinue
    if ($daemonDisabled) {
        Write-Host "     ✅ Gradle daemon disabled (Windows safe)" -ForegroundColor Green
    } else {
        Write-Host "     ⚠️  Warning: Gradle daemon may not be explicitly disabled" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  gradle.properties not found" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# PHASE 6: ANDROID DOCTOR CHECK
# ============================================================================
Write-Host "PHASE 6: Android Environment Check..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "  🏥 Running: flutter doctor -v" -ForegroundColor Cyan
Write-Host ""

flutter doctor -v
Write-Host ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ CLEANUP COMPLETE!                                         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "   1. Disconnect and reconnect your Android device via USB" -ForegroundColor White
Write-Host "   2. Run: flutter run -v" -ForegroundColor White
Write-Host "   3. Monitor for errors" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  IF BUILD STILL FAILS:" -ForegroundColor Yellow
Write-Host "   • Check: flutter doctor -v" -ForegroundColor White
Write-Host "   • Clear global Flutter cache: flutter clean" -ForegroundColor White
Write-Host "   • Check Android SDK: android\build.gradle.kts compileSdk version" -ForegroundColor White
Write-Host "   • Verify device: adb devices -l" -ForegroundColor White
Write-Host ""

Write-Host "📚 DOCUMENTATION:" -ForegroundColor Cyan
Write-Host "   See WINDOWS_BUILD_TROUBLESHOOTING.md for detailed explanations" -ForegroundColor White
Write-Host ""

Write-Host "✨ Cleanup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
