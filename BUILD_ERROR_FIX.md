# Build Error Fix - File Locked

## Error
```
java.nio.file.FileSystemException: libVkLayer_khronos_validation.so: 
The process cannot access the file because it is being used by another process
```

## Root Cause
Windows file lock issue - another Flutter/Gradle process is still running and holding file handles.

## Fix Applied

### Step 1: Kill All Running Processes
```bash
taskkill /F /IM dart.exe
taskkill /F /IM java.exe
```

### Step 2: Clean Build
```bash
flutter clean
```

### Step 3: Rebuild
```bash
flutter run
```

## If Error Persists

### Option 1: Restart IDE
1. Close Cursor/VS Code completely
2. Wait 10 seconds
3. Reopen and try again

### Option 2: Restart Computer
Sometimes Windows file locks persist - a restart clears everything.

### Option 3: Delete Build Folder Manually
```bash
# Close all terminals
# Then manually delete:
C:\Users\ADMIN\Documents\KSR_Hackathon\build\
```

Then run:
```bash
flutter pub get
flutter run
```

## Prevention

### Always Stop App Properly
- Don't force quit terminal
- Use `q` in flutter run to quit properly
- Let Gradle finish cleanly

### One Build at a Time
- Don't run multiple `flutter run` commands
- Check running processes before building

## Quick Fix Script

If error happens again, run these commands in order:

```bash
# Stop all Flutter processes
taskkill /F /IM dart.exe
taskkill /F /IM java.exe
timeout /t 2

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## Success
App should now build and deploy successfully! 🚀
