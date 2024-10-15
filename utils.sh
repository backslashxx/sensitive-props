#!/system/bin/busybox sh

set_permissions() { # Handle permissions without errors
    [ -e "$1" ] && chmod "$2" "$1"
}

exist_resetprop() { # Reset a property if it exists
    getprop "$1" | grep -q '.' && resetprop -v -n "$1"
}

check_resetprop() { # Reset a property if it exists and doesn't match the desired value
    VALUE="$(resetprop -v "$1")"
    [ ! -z "$VALUE" ] && [ "$VALUE" != "$2" ] && resetprop -v -n "$1" "$2"
}

maybe_resetprop() { # Reset a property if it exists and matches a pattern
    VALUE="$(resetprop -v "$1")"
    [ ! -z "$VALUE" ] && echo "$VALUE" | grep -q "$2" && resetprop -v -n "$1" "$3"
}

replace_value_resetprop() { # Replace a substring in a property's value
    VALUE="$(resetprop -v "$1")"
    [ -z "$VALUE" ] && return
    VALUE_NEW="$(echo -n "$VALUE" | sed "s|${2}|${3}|g")"
    [ "$VALUE" == "$VALUE_NEW" ] || resetprop -v -n "$1" "$VALUE_NEW"
}

# Since it is unsafe to change full length strings within binary image pages
# We must specify short strings for the search so that there are not binary chunks in between
# magiskboot hexpatch issue
# ref: https://github.com/topjohnwu/Magisk/issues/8315
hexpatch_deleteprop() {
    search_string="$1"                                                           # The string to search for in property names
    search_hex=$(echo -n "$search_string" | xxd -p | tr '[:lower:]' '[:upper:]') # Hex representation in uppercase

    # Path to magiskboot
    magiskboot_path=$(which magiskboot 2>/dev/null || find /data/adb /data/data/me.bmax.apatch/patch/ -name magiskboot 2>/dev/null)

    # Generate a random LOWERCASE alphanumeric string of the required length, but only using 0-9 and a-f
    replacement_string=$(cat /dev/urandom | tr -dc '0-9a-f' | head -c ${#search_string})

    # Trim if replacement is too long (shouldn't happen often)
    [[ ${#replacement_string} -gt ${#search_string} ]] && replacement_string="${replacement_string:0:${#search_string}}"

    # Convert the full replacement string to hex (once, at the top scope) and ensure it's in uppercase
    replacement_hex=$(echo -n "$replacement_string" | xxd -p | tr '[:lower:]' '[:upper:]')

    # Get property list from search string
    # Then get a list of property file names using resetprop -Z and pipe it to find
    getprop | grep "$search_string" | cut -d'[' -f2 | cut -d']' -f1 | while read prop_name; do
        resetprop -Z "$prop_name" | cut -d' ' -f2 | cut -d':' -f3 | while read -r prop_file_name_base; do
            # Use find to locate the actual property file (potentially in a subdirectory)
            # and iterate directly over the found paths
            find /dev/__properties__/ -name "*$prop_file_name_base*" | while read -r prop_file; do
                # echo "Patching $prop_file: $search_hex -> $replacement_hex"
                "$magiskboot_path" hexpatch "$prop_file" "$search_hex" "$replacement_hex" >/dev/null 2>&1

                # Check if the patch was successfully applied
                if [ $? -eq 0 ]; then
                    echo "Successfully patched $prop_file (replaced part of '$search_string')"
                    #else
                    #echo "Failed to patch $prop_file (replacing part of '$search_string')."
                fi
            done
        done
    done
}

exist_hexpatch_deleteprop() { # Reset a property if it exists
    [ -n "$(resetprop -Z "$1" | cut -d' ' -f2)" ] && hexpatch_deleteprop "$1"
}

hexpatch_replaceprop() {
    local search_string="$1" # The string to search for in property names
    local new_string="$2"    # The new string to replace the search string with

    # Check if lengths match, abort if not
    if [ ${#search_string} -ne ${#new_string} ]; then
        abort "Error: Searching/Replacing string using hexpatch must have the new string to be of the same length." >&2
    fi

    search_hex=$(echo -n "$search_string" | xxd -p | tr '[:lower:]' '[:upper:]') # Hex representation in uppercase
    replace_hex=$(echo -n "$new_string" | xxd -p | tr '[:lower:]' '[:upper:]')   # Hex representation of the new string, also uppercase

    # Path to magiskboot
    magiskboot_path=$(which magiskboot 2>/dev/null || find /data/adb /data/data/me.bmax.apatch/patch/ -name magiskboot 2>/dev/null)

    # Get property list from search string
    # Then get a list of property file names using resetprop -Z and pipe it to find
    getprop | grep "$search_string" | cut -d'[' -f2 | cut -d']' -f1 | while read prop_name; do
        resetprop -Z "$prop_name" | cut -d' ' -f2 | cut -d':' -f3 | while read -r prop_file_name_base; do
            # Use find to locate the actual property file (potentially in a subdirectory)
            # and iterate directly over the found paths
            find /dev/__properties__/ -name "*$prop_file_name_base*" | while read -r prop_file; do
                # echo "Patching $prop_file: $search_hex -> $replace_hex"
                "$magiskboot_path" hexpatch "$prop_file" "$search_hex" "$replace_hex" >/dev/null 2>&1

                # Check if the patch was successfully applied
                if [ $? -eq 0 ]; then
                    echo "Successfully patched $prop_file (renamed part of '$search_string' to '$new_string')"
                    #else
                    #echo "Failed to patch $prop_file (renaming part of '$search_string')."
                fi
            done
        done
    done
}