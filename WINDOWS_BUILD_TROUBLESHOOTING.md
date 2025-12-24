# 🔧 Flutter Windows Build Troubleshooting Guide

## Table of Contents
1. [Root Cause Analysis](#root-cause-analysis)
2. [Immediate Fixes](#immediate-fixes)
3. [Permanent Configuration](#permanent-configuration)
4. [Advanced Troubleshooting](#advanced-troubleshooting)
5. [Prevention & Best Practices](#prevention--best-practices)
6. [When to Escalate](#when-to-escalate)

---

## Root Cause Analysis

### Error: PathExistsException (errno = 183)
**What it means:** Windows error code 183 = "File already exists"

**Why it happens on Windows:**
- Windows file locking is more aggressive than Unix/Linux
- Gradle daemon processes hold file handles longer
- Antivirus software may lock files during build

**Solution:** Disable Gradle daemon (already configured in `gradle.properties`)

---

### Error: R.jar already contains entry (R.class)
**What it means:** Android build compiled resources twice

**Why it happens:**
- Incomplete previous build left stale `build/` artifacts
- Gradle cache contains old resource entries
- File system lock prevented proper deletion

**Solution:** Delete `build/` directories and `.gradle/` cache completely

---

### Error: cannot overwrite existing files
**What it means:** Build tried to write to a file that's locked

**Why on Windows specifically:**
- Windows file locks are held longer than Unix
- Gradle daemon + Flutter watching files = contention
- Explorer or IDE may have folders locked

**Solution:** 
1. Kill all Java/Gradle processes
2. Disable Gradle daemon
3. Use in-process Kotlin compilation

---

### Error: Issues with plugins (flutter_tts, camera, lifecycle)
**What it means:** Plugin version conflicts or missing AndroidX

**Why it happens:**
- Old plugins not compatible with AGP 8.11.1
- Mixed AndroidX/legacy Android library dependencies
- Plugin dependency trees conflict

**Versions that work:**
- `flutter_tts: ^4.2.3` ✅ (compatible with AGP 8.11)
- `camera: ^0.11.3` ✅ (uses camera_android_camerax)
- `permission_handler: ^11.0.0` ✅ (AndroidX ready)
- AGP 8.11.1 ✅ (latest stable)
- Kotlin 2.2.20 ✅ (latest stable)

**Solution:** Ensure AndroidX is enabled (configured in `gradle.properties`)

---

## Immediate Fixes

### Quick Fix (Try First)
```powershell
# 1. Kill processes
Get-Process | Where-Object {$_.ProcessName -match "gradle|dart|java"} | Stop-Process -Force -ErrorAction SilentlyContinue

# 2. Clean
flutter clean
flutter pub get

# 3. Rebuild
flutter run -v
```

### If Quick Fix Doesn't Work → Full Cleanup
```powershell
# Run the provided PowerShell script
powershell -ExecutionPolicy Bypass -File WINDOWS_BUILD_FIX.ps1
```

This script:
- ✅ Kills all Gradle/Dart/Java processes
- ✅ Deletes build artifacts
- ✅ Clears Gradle local cache
- ✅ Refreshes dependencies
- ✅ Verifies configuration

---

## Permanent Configuration

### 1. gradle.properties (Already Applied)
✅ **Applied:** Enhanced configuration with:
- Gradle daemon disabled (prevents file locking)
- In-process Kotlin compilation (prevents daemon hangs)
- Incremental compilation disabled (more stable on Windows)
- Increased timeouts for I/O
- Full AndroidX support enabled

### 2. settings.gradle.kts (Current)
✅ **Status:** Already correct
- AGP 8.11.1 ✅
- Kotlin 2.2.20 ✅
- Plugin loader configured ✅

### 3. app/build.gradle.kts (Current)
✅ **Status:** Already correct
- Java 17 ✅
- MinSdk/targetSdk from Flutter ✅
- Kotlin options set ✅

### 4. pubspec.yaml (Current)
✅ **Status:** Dependencies are compatible
- `flutter_tts: ^4.2.3` ✅
- `camera: ^0.11.3` ✅
- All plugins support AndroidX ✅

---

## Advanced Troubleshooting

### If Build Still Fails After Full Cleanup

#### Step 1: Verify Android SDK
```powershell
flutter doctor -v

# Look for:
# ✓ Android SDK version (check compileSdk in app/build.gradle.kts)
# ✓ Build Tools version
# ✓ Platform Tools (adb)
```

#### Step 2: Check Device Connection
```powershell
adb devices -l

# Output should show:
# emulator-5554  device product:generic_x86_64 model:Android SDK built for x86_64 device:generic_x86_64
# OR
# DEVICE_SERIAL   device product:actual_device model:actual_device device:actual_device
```

#### Step 3: Run Verbose Build
```powershell
flutter run -v 2>&1 | Tee-Object build_debug.log

# Save output to file for analysis
# Look for first actual error (not warnings)
```

#### Step 4: Clean Global Cache (Aggressive)
```powershell
# WARNING: This affects all Flutter projects!
# Only do if project-level cleanup doesn't work

flutter pub cache clean --force
flutter pub get
```

#### Step 5: Verify Plugin Build Scripts
```powershell
# Check that plugins are generating .so files correctly
cd android
./gradlew clean
./gradlew :app:compileDebugJavaWithJavac -v
# Look for plugin compilation in output
```

---

## Prevention & Best Practices

### Before Starting Development
```powershell
# 1. Verify environment
flutter doctor -v

# 2. Get dependencies
flutter pub get

# 3. Build once to warm up Gradle
flutter build apk --debug
```

### During Development

#### ✅ DO:
- Use `flutter run` (not `flutter run -v` for routine work)
- Keep one terminal for `flutter run`, another for edits
- Rebuild only when necessary (`r` key)
- Use hot reload (`R` key) for small changes

#### ❌ DON'T:
- Kill terminals abruptly (use `q` to quit `flutter run`)
- Delete Android gradle files manually (use `flutter clean`)
- Run multiple `flutter run` instances simultaneously
- Keep IDE in file explorer view of android/ folder while building

### Weekly Maintenance
```powershell
# Every week or after many builds:
flutter clean
flutter pub get

# Monthly:
flutter pub upgrade  # Check for updates
```

### Prevent Gradle Daemon Issues
```powershell
# In terminal BEFORE building, ensure no hung daemons:
Get-Process | Where-Object {$_.ProcessName -match "gradle"} | ForEach-Object {
    Write-Host "Gradle process: $($_.ProcessName) - PID $($_.Id)"
    Stop-Process -Id $_.Id -Force
}
```

---

## When to Escalate

Contact a senior Flutter engineer if:

### 1. After Full Cleanup, Still Getting Same Error
- **Action:** Collect logs and check Android SDK
```powershell
flutter run -v > error_log.txt 2>&1
# Attach error_log.txt with screenshot of error
```

### 2. Device Shows "Device Offline"
```powershell
adb kill-server
adb devices -l
# If still offline, restart device and reconnect
```

### 3. Build Fails with "Gradle Version Incompatible"
- **Action:** Check Flutter version and AGP compatibility
```powershell
flutter --version
# Check AGP in: android/settings.gradle.kts
```

### 4. Incremental Build Always Crashes
- **Action:** Disable incremental builds temporarily
```powershell
# In gradle.properties, set:
# kotlin.incremental=false
# (already configured)
```

---

## Quick Reference: File Locations

| Purpose | Path | Action if Build Fails |
|---------|------|-----|
| Gradle cache | `android/.gradle/` | ✅ Safe to delete |
| Build output | `build/` | ✅ Safe to delete |
| App build output | `android/app/build/` | ✅ Safe to delete |
| Dependencies | `pubspec.lock` | ✅ Safe to delete (regenerated) |
| Gradle settings | `android/gradle.properties` | ⚠️ Check content, don't delete |
| Android config | `android/settings.gradle.kts` | ⚠️ Don't modify unless necessary |
| App config | `android/app/build.gradle.kts` | ⚠️ Don't modify unless necessary |
| Local properties | `android/local.properties` | ⚠️ Don't delete (contains Flutter SDK path) |

---

## Gradle Properties Explained

**Your Current Settings:**

```properties
# High memory allocation for Gradle JVM
org.gradle.jvmargs=-Xmx8G

# Prevents Windows file locking issues
org.gradle.daemon=false

# Allows simultaneous Gradle worker threads
org.gradle.parallel=true

# Kotlin compiles in same process (Windows stable)
kotlin.compiler.execution.strategy=in-process

# Disables incremental Kotlin compilation (safer on Windows)
kotlin.incremental=false

# Enables modern Android libraries
android.useAndroidX=true

# Migrates old Android libraries to AndroidX
android.enableJetifier=true
```

These settings prioritize **stability over speed** on Windows.

---

## Testing Your Configuration

After applying fixes:

```powershell
# 1. Verify no processes
Get-Process | Where-Object {$_.ProcessName -match "gradle|dart|java"}
# Should return: nothing

# 2. Verify gradle.properties
Select-String -Path "android\gradle.properties" -Pattern "org.gradle.daemon=false"
# Should return: org.gradle.daemon=false

# 3. Test build
flutter run

# 4. If successful, mark a commit
git add -A
git commit -m "fix: Windows build configuration for stability"
```

---

## Additional Resources

- [Flutter Build on Windows (Docs)](https://flutter.dev/docs/deployment/windows)
- [Android Gradle Plugin Release Notes](https://developer.android.com/build/releases/gradle-plugin)
- [Gradle Performance (Official)](https://gradle.org/performance)
- [Kotlin Compiler Settings](https://kotlinlang.org/docs/gradle.html)

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-24  
**Flutter Version Tested:** 3.10+  
**Gradle Plugin:** 8.11.1  
**Kotlin:** 2.2.20
