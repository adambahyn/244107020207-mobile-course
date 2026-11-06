#!/usr/bin/env bash
# Uji kebocoran memori (Langkah 5 jobsheet): PSS sebelum vs sesudah
# navigasi daftar -> detail -> kembali, 5 kali. Ditulis ke docs/memori.txt
set -u
export PATH="$PATH:/c/Users/adamb/AppData/Local/Android/Sdk/platform-tools"
P=com.example.campus_notify
OUT=../docs/memori.txt
pss() { adb shell dumpsys meminfo "$P" | awk '/TOTAL PSS/ {printf "PSS=%s KB  RSS=%s KB\n", $3, $6}'; }

adb shell am force-stop com.tokopedia.tkpd 2>/dev/null
adb shell am force-stop "$P"
adb shell am start -W -n "$P/.MainActivity" >/dev/null
sleep 6

{
  echo "== sesudah load awal =="
  pss
  echo "== sesudah 5x (detail -> kembali) =="
} > "$OUT"

for i in 1 2 3 4 5; do
  adb shell input tap 540 640   # kartu pertama
  sleep 2
  adb shell input keyevent 4    # kembali
  sleep 1
done
pss >> "$OUT"
adb shell dumpsys window | grep mCurrentFocus >> "$OUT"
cat "$OUT"
