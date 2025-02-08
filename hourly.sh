#!/bin/sh
# make sure to hardcode moddir as we wont be inside 
# root manager env anymore when cronjobs are ran
MODDIR="/data/adb/modules/sensitive_props"
# Using util_functions.sh
. $MODDIR/util_functions.sh

hexpatch_deleteprop "LSPosed" "marketname" "custom.device" "modversion" "lineage" "aospa" "pixelexperience" "evolution" "pixelos" "pixelage" "crdroid" "crDroid" "aospa"  "aicp" "arter97" "blu_spark" "cyanogenmod" "deathly" "elementalx" "elite" "franco" "hadeskernel" "morokernel" "noble" "optimus" "slimroms" "sultan" "aokp" "bharos" "calyxos" "calyxOS" "divestos" "emteria.os" "grapheneos" "indus" "kali" "nethunter" "omnirom" "paranoid" "replicant" "resurrection" "rising" "remix" "shift" "volla" "icosa" "kirisakura" "infinity" "Infinity"

# EOF
