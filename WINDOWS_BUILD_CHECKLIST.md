# ✅ WINDOWS FLUTTER BUILD - QUICK REFERENCE CHECKLIST

## 🚨 Build Failed? Follow This Order

### ✅ Level 1: Quick Fix (30 seconds)
- [ ] Disconnect USB cable, reconnect device
- [ ] Run: `flutter clean && flutter pub get`
- [ ] Run: `flutter run -v`

**If still failing → Level 2**

---

### ✅ Level 2: Kill Processes & Clean (2 minutes)
```powershell
# Kill all Java/Gradle/Dart processes
Get-Process | Where-Object {$_.ProcessName -match "gradle|dart|java"} | Stop-Process -Force -ErrorAction SilentlyContinue
[System.GC]::Collect()
Start-Sleep -Seconds 3

# Clean everything
flutter clean
flutter pub get
flutter run -v
```

**If still failing → Level 3**

---

### ✅ Level 3: Full Cleanup (5-10 minutes)
Run the automated script:
```powershell
powershell -ExecutionPolicy Bypass -File WINDOWS_BUILD_FIX.ps1
```

Then run:
```powershell
flutter run -v
```

**If still failing → Level 4**

---

### ✅ Level 4: Verify Configuration (5 minutes)

#### Check 1: gradle.properties Content
```powershell
Get-Content android\gradle.properties
```

Must contain:
- `org.gradle.daemon=false` ✅
- `kotlin.compiler.execution.strategy=in-process` ✅
- `android.useAndroidX=true` ✅

#### Check 2: Device Connection
```powershell
adb devices -l
```

Must show device as `device` (not `offline`)

#### Check 3: Flutter Doctor
```powershell
flutter doctor -v
```

All items should have ✓ (green checkmarks)

#### Check 4: Android SDK Version
```powershell
# Check app/build.gradle.kts:
# compileSdk = flutter.compileSdkVersion
# This should match installed Android SDK
flutter --version
# Then check: android\build.gradle.kts for versions
```

**If still failing → Level 5 (Escalate)**

---

### ✅ Level 5: Diagnostic Logging

```powershell
# Generate detailed build log
flutter run -v 2>&1 | Tee-Object flutter_build_error.log

# This creates flutter_build_error.log
# Share this file with senior engineer
```

---

## 🔍 Common Error Messages & Quick Fixes

### Error: "PathExistsException (errno = 183)"
```powershell
# Windows file lock issue
flutter clean
# Then run Level 3 cleanup script
```

### Error: "R.jar already contains entry (R.class)"
```powershell
# Gradle cache corruption
Remove-Item -Path "android\.gradle" -Recurse -Force
Remove-Item -Path "build" -Recurse -Force
flutter pub get
flutter run -v
```

### Error: "Gradle task assembleDebug failed"
```powershell
# Run full cleanup
powershell -ExecutionPolicy Bypass -File WINDOWS_BUILD_FIX.ps1
```

### Error: "Device Offline"
```powershell
# USB connection lost
adb kill-server
adb devices -l
# Reconnect USB cable
```

### Error: "Cannot overwrite existing files"
```powershell
# Another Gradle process running
Get-Process | Where-Object {$_.ProcessName -match "gradle"} | Stop-Process -Force
flutter run -v
```

---

## 🛠️ Regular Maintenance Schedule

### Daily (Before You Start)
- [ ] Verify device: `adb devices -l`
- [ ] Doctor check: `flutter doctor`

### After Every 5 Builds
- [ ] Clean cache: `flutter clean && flutter pub get`

### Weekly
- [ ] Full cleanup: Run `WINDOWS_BUILD_FIX.ps1` script
- [ ] Doctor check: `flutter doctor -v`

### Monthly
- [ ] Check for updates: `flutter upgrade`
- [ ] Update packages: `flutter pub upgrade`
- [ ] Clear global cache: `flutter pub cache clean --force`

---

## 📋 Configuration Checklist

### Your Environment Should Have

#### gradle.properties
```
✅ org.gradle.daemon=false
✅ kotlin.compiler.execution.strategy=in-process
✅ kotlin.incremental=false
✅ android.useAndroidX=true
✅ android.enableJetifier=true
✅ org.gradle.parallel=true
```

#### pubspec.yaml
```
✅ flutter_tts: ^4.2.3
✅ camera: ^0.11.3
✅ permission_handler: ^11.0.0
✅ flutter_dotenv: ^5.1.0
✅ google_generative_ai: ^0.4.7
```

#### Android/settings.gradle.kts
```
✅ AGP: com.android.application version "8.11.1"
✅ Kotlin: org.jetbrains.kotlin.android version "2.2.20"
```

---

## 🎯 Prevention Tips

### DO ✅
- Use `flutter run` (normal mode, not verbose)
- Press `r` to reload, `R` to restart
- Quit cleanly with `q` (don't kill terminal)
- Keep project files on local SSD (not network drive)
- Exclude `build/` and `.gradle/` from antivirus scanning

### DON'T ❌
- Don't delete `android/local.properties` (contains SDK path)
- Don't manually edit `pubspec.lock`
- Don't run multiple `flutter run` instances
- Don't use IDE file explorer for `android/` folder during builds
- Don't disable Gradle daemon and parallel builds simultaneously

---

## 📞 When to Ask for Help

Before escalating, ensure you have:
1. Run Level 3 cleanup script
2. Run `flutter doctor -v` (save output)
3. Run `flutter run -v` and capture error
4. Check `WINDOWS_BUILD_TROUBLESHOOTING.md`

Then provide:
- `flutter_build_error.log` (from Level 5 diagnostic)
- Output of `flutter doctor -v`
- Output of `adb devices -l`
- Screenshot of error message

---

## 🚀 Quick Command Reference

```powershell
# Status check
flutter doctor -v
adb devices -l

# Clean slate
flutter clean
flutter pub get

# Build & run
flutter run              # Normal build
flutter run -v          # Verbose (for debugging)
flutter run --release   # Release build

# Process management
Get-Process | Where-Object {$_.ProcessName -match "gradle|dart"} | Stop-Process -Force

# Clear caches
flutter pub cache clean --force

# Run tests
flutter test
```

---

**Last Updated:** 2025-12-24  
**For:** Windows 10/11 with Flutter 3.10+  
**Status:** ✅ Verified & Working
