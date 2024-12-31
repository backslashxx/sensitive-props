#!/bin/sh
PATH=/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk:$PATH

if [ "$API" -lt 29 ]; then
  abort "! Only support Android 10+ devices"
fi

# Set Module permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644

# Running the service early using busybox
[ -f "$MODPATH/service.sh" ] && sh "$MODPATH/service.sh" 2>&1

ui_print "? Please uninstall this module before dirty-flashing/updating the ROM."
