set -x
mkdir -p shots
P=ru.volshebnymir.lumo
adb install -r android/app/build/outputs/apk/release/app-release.apk
adb shell pm grant $P android.permission.POST_NOTIFICATIONS || true
adb shell wm size
shot() {
  adb shell am force-stop $P
  adb shell am start -n $P/.MainActivity $2
  sleep 10
  adb exec-out screencap -p > shots/$1.png
}
shot 1-chats "--ez demo true"
shot 2-chat "--ez demo true --es screen chat"
shot 3-call "--ez demo true --es screen call"
shot 4-profile "--ez demo true --es screen profile"
shot 5-settings "--ez demo true --es screen settings"
