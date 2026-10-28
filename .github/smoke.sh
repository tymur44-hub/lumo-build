set -x
mkdir -p shots
P=ru.volshebnymir.lumo
adb install -r android/app/build/outputs/apk/release/app-release.apk
adb shell pm grant $P android.permission.POST_NOTIFICATIONS || true
shot() {
  adb shell am force-stop $P
  adb logcat -c
  adb shell am start -n $P/.MainActivity $2
  sleep 9
  adb exec-out screencap -p > shots/$1.png
  if adb shell pidof $P >/dev/null; then echo "::notice::$1 ALIVE"; else echo "::error::$1 DEAD"; fi
  adb logcat -d | grep -E "FATAL EXCEPTION|AndroidRuntime" -A 25 | head -40 | while IFS= read -r l; do echo "::error::$1 ${l}"; done
}
shot 1-login ""
shot 2-chats "--ez demo true"
shot 3-chat "--ez demo true --es screen chat"
shot 4-settings "--ez demo true --es screen settings"
shot 5-profile "--ez demo true --es screen profile"
shot 6-person "--ez demo true --es screen person"
shot 7-call "--ez demo true --es screen call"
adb shell am force-stop $P; adb logcat -c
adb shell am start -n $P/.MainActivity --ez demo true --es screen selftest
sleep 12
(adb logcat -d | grep -E "LUMO_SELFTEST|FATAL|webrtc|WebRtc" | head -150; echo end) > shots/selftest.txt
adb exec-out screencap -p > shots/8-selftest.png
shot 9-qr "--ez demo true --es screen qr"
shot 11-menu "--ez demo true --es screen menu"
shot 12-edit "--ez demo true --es screen edit"
shot 13-privacy "--ez demo true --es screen privacy"
adb shell am force-stop $P
adb shell appops set $P SYSTEM_ALERT_WINDOW allow || true
adb shell am start -n $P/.MainActivity --ez demo true --es screen ring
sleep 3
adb shell input keyevent KEYCODE_HOME
sleep 1
adb shell input keyevent KEYCODE_SLEEP
sleep 14
( adb shell dumpsys power | grep -E "mWakefulness=" | head -2
  adb shell appops get $P USE_FULL_SCREEN_INTENT
  adb shell dumpsys notification --noredact | grep -E "pkg=ru.volshebnymir|fullscreenIntent|category=call|Lumo|channel=calls" | head -30
  adb logcat -d | grep -iE "fullscreen|FullScreenIntent|BAL|Lumo|AndroidRuntime" | tail -40
  adb shell dumpsys activity activities | grep -E "mResumedActivity|topResumed" | head -5
  echo end ) > shots/power.txt
adb exec-out screencap -p > shots/10-locked-ring.png
