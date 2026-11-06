#!/usr/bin/env bash
# Skenario ukur performa yang sama untuk before/after.
# Pakai: tool/ukur.sh <label> <file-screenshot>
# Menulis: screenshots/<file-screenshot>, docs/metrics-<label>.txt
set -u
export PATH="$PATH:/c/Users/adamb/AppData/Local/Android/Sdk/platform-tools"
LABEL=${1:?label (before|after)}
SHOT=${2:?nama file screenshot}
P=com.example.campus_notify
APK=build/app/outputs/flutter-apk/app-profile.apk
DOC=../docs/metrics-$LABEL.txt

adb install -r "$APK" >/dev/null 2>&1
adb shell am force-stop com.tokopedia.tkpd 2>/dev/null
adb shell am force-stop "$P"
adb logcat -c
{
  echo "== cold start (am start -W) =="
  adb shell am start -W -n "$P/.MainActivity" | grep -E 'TotalTime|WaitTime'
} > "$DOC"
sleep 7

# skenario: scroll cepat 6x, buka detail, kembali, pull-to-refresh
for _ in 1 2 3 4 5 6; do adb shell input swipe 540 1800 540 500 220; done
sleep 1
adb shell input tap 540 640
sleep 2
adb shell input keyevent 4
sleep 2
adb shell input swipe 540 600 540 1800 400
sleep 4

adb shell dumpsys window | grep mCurrentFocus >> "$DOC"
adb exec-out screencap -p > "../screenshots/$SHOT"
{
  echo "== frame (FrameTiming, sama dengan sumber DevTools) =="
  adb logcat -d -s flutter:V | grep 'PERF|' | tail -2
  echo "== memori =="
  adb shell dumpsys meminfo "$P" | grep -E 'TOTAL PSS'
} >> "$DOC"
cat "$DOC"