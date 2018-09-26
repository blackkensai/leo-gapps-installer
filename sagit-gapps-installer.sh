#!/sbin/sh

ch_con_recursive() {
  dirs=$(echo "$@" | awk '{ print substr($0, index($0,$1)) }');
  for i in $dirs; do
    find "$i" -exec LD_LIBRARY_PATH=/system/lib /system/lib64 /system/toolbox chcon u:object_r:system_file:s0 {} +;
    find "$i" -exec LD_LIBRARY_PATH=/system/lib /system/lib64 /system/bin/toolbox chcon u:object_r:system_file:s0 {} +;
    find "$i" -exec chcon u:object_r:system_file:s0 {} +;
  done;
}

set_perm_recursive() {
  dirs=$(echo "$@" | awk '{ print substr($0, index($0,$5)) }');
  for i in $dirs; do
    chown -R "$1:$2" "$i";
    find "$i" -type d -exec chmod "$3" {} +;
    find "$i" -type f -exec chmod "$4" {} +;
  done;
}

install_busybox() {
  cp busybox-arm /system/xbin
  chmod 0755 /system/xbin/busybox-arm
  cp tar-arm /system/xbin
  chmod 0755 /system/xbin/tar-arm
  cp unzip-arm /system/xbin
  chmod 0755 /system/xbin/unzip-arm
  cp zip-arm /system/xbin
  chmod 0755 /system/xbin/zip-arm
}

# filepath target
folder_extract() {
  if [[ $1 == *"tablet"* ]]; then
    return
  fi
  pkg=$(echo $1 | awk '{print substr($1, 0, index($1,".")-1)}')
  pkg=$(echo $pkg | awk '{print substr($1,index($1,"/")+1)}')
  echo "$1 $pkg => $2"
  busybox-arm tar -xf "$1" -C "$2" "$pkg/common";
  busybox-arm tar -xf "$1" -C "$2" "$pkg/nodpi";
  busybox-arm tar -xf "$1" -C "$2" "$pkg/240-320-480";
  #tar -xJf "$1" -C "$2" "$pkg/common";
  #tar -xJf "$1" -C "$2" "$pkg/nodpi";
  #cp -rvf /sdcard/open_gapps-arm64-5.1-pico-20160721/$2/. /system/;
  # install -m 644 src dest
  if [ -d "$2/$pkg/common" ]; then
    cp -rvf "$2/$pkg/common/." /system/
  fi
  if [ -d "$2/$pkg/nodpi" ]; then
    cp -rvf "$2/$pkg/nodpi/." /system/
  fi
  if [ -d "$2/$pkg/240-320-480" ]; then
    cp -rvf "$2/$pkg/240-320-480/." /system/
  fi
}

#/sdcard/open_gapps-arm64-5.1-pico-20160207/configupdater/nodpi/. -> /system/.
#/sdcard/open_gapps-arm64-5.1-pico-20160207/configupdater/nodpi/./priv-app -> /system/./priv-app
fix_gapps() {
    # find /system/vendor/pittpatt -type d -exec chown 0:2000 '{}' \;
    # set_perm_recursive 0 0 755 644 "/system/app" "/system/framework" "/system/lib" "/system/lib64" "/system/priv-app" "/system/usr/srec" "/system/vendor/pittpatt" "/system/etc/permissions" "/system/etc/preferred-apps";
    # ch_con_recursive "/system/app" "/system/framework" "/system/lib" "/system/lib64" "/system/priv-app" "/system/usr/srec" "/system/vendor/pittpatt" "/system/etc/permissions" "/system/etc/preferred-apps" "/system/addon.d";
}

others() {
  SYSTEM=/system
  g_prop=$SYSTEM/etc/g.prop
sed -i "s/ro.error.receiver.system.apps=.*/ro.error.receiver.system.apps=com.google.android.gms/g" $SYSTEM/build.prop
sed -i "\:# Apply build.prop changes (from GApps Installer):a \    sed -i \"s/ro.error.receiver.system.apps=.*/ro.error.receiver.system.apps=com.google.android.gms/g\" $SYSTEM/build.prop" $bkup_tail
}

fix_permissions() {
  find /system/priv-app/ -name '*.apk' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/app/ -name '*.apk' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/priv-app/ -type d -perm 771 -print -exec chmod 0755 '{}' \;
  find /system/app/ -type d -perm 771 -print -exec chmod 0755 '{}' \;
  find /system/etc/permissions/ -name '*.xml' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/lib -name '*.so' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/lib64 -name '*.so' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/etc/sysconfig/ -name '*.xml' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/framework/ -name '*.jar' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/etc/default-permissions/ -name '*.xml' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/etc/preferred-apps -name '*.xml' -perm 660 -print -exec chmod 0644 '{}' \;
  find /system/etc/ -type d -perm 771 -print -exec chmod 0755 '{}' \;
  find /system/usr/ -type d -perm 771 -print -exec chmod 0755 '{}' \;
  find /system/usr/srec/en-US -name '*' -perm 660 -print -exec chmod 0644 '{}' \;
}

pkg_path=`pwd`
tmp_path="$pkg_path/tmp"
echo Root dir: $pkg_path
echo Temp dir: $tmp_path
mkdir $tmp_path

mount -o rw,remount /system
install_busybox
ll $tmp_path
for f in $(ls Core); do
    folder_extract "Core/$f" $tmp_path
done;
for f in $(ls GApps); do
    folder_extract "GApps/$f" $tmp_path
done;
fix_gapps
fix_permissions
mount -o ro,remount /system
#rm -rf $tmp_path/*
