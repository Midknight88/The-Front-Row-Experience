#!/usr/bin/env bash
# Patches the generated Android project: permissions, version, launcher icon.
set -euo pipefail
cd "$(dirname "$0")/.."
M=android/app/src/main/AndroidManifest.xml
VC="${VERSION_CODE:-1}"; VN="${VERSION_NAME:-1.0.$VC}"

# Bluetooth without location (Android 12+), location only on Android 11 and older,
# microphone for "follow the music" beat detection.
python3 - "$M" <<'PY'
import sys,re
p=sys.argv[1];s=open(p).read()
if 'xmlns:tools' not in s:
    s=s.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android"','<manifest xmlns:android="http://schemas.android.com/apk/res/android"\n    xmlns:tools="http://schemas.android.com/tools"',1)
perms='''
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" tools:targetApi="s" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
'''
if 'BLUETOOTH_SCAN' not in s:
    s=s.replace('<uses-permission android:name="android.permission.INTERNET" />','<uses-permission android:name="android.permission.INTERNET" />'+perms,1)
# keep the screen on during a show is handled in the web app; keep portrait-friendly defaults
open(p,'w').write(s)
PY

# version
sed -i -E "s/versionCode [0-9]+/versionCode $VC/; s/versionName \"[^\"]*\"/versionName \"$VN\"/" android/app/build.gradle
grep -n "versionCode\|versionName" android/app/build.gradle
grep -n "permission" "$M"
