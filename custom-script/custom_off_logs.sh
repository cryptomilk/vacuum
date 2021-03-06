#!/usr/bin/env bash
# Disables most log files creations and log uploads on the vacuum

LIST_CUSTOM_PRINT_USAGE+=("custom_print_usage_01_off_logs")
LIST_CUSTOM_PRINT_HELP+=("custom_print_help_01_off_logs")
LIST_CUSTOM_PARSE_ARGS+=("custom_parse_args_01_off_logs")
LIST_CUSTOM_FUNCTION+=("custom_function_01_off_logs")
DISABLE_LOGS=${DISABLE_LOGS:-"0"}

function custom_print_usage_01_off_logs() {
    cat << EOF

Custom parameters for '${BASH_SOURCE[0]}':
[--disable-logs]
EOF
}

function custom_print_help_01_off_logs() {
    cat << EOF

Custom options for '${BASH_SOURCE[0]}':
  --disable-logs             Disables most log files creations and log uploads on the vacuum
EOF
}

function custom_parse_args_01_off_logs() {
    case ${PARAM} in
        *-disable-logs)
            DISABLE_LOGS=1
            ;;
        -*)
            return 1
            ;;
    esac
}

function custom_function_01_off_logs() {
    if [ $DISABLE_LOGS -eq 1 ]; then
        echo "+ Disabling logging"

        # UPLOAD_METHOD=0
        sed -i -E 's/(UPLOAD_METHOD=)([0-9]+)/\10/' "${IMG_DIR}/opt/rockrobo/rrlog/rrlog.conf"
        sed -i -E 's/(UPLOAD_METHOD=)([0-9]+)/\10/' "${IMG_DIR}/opt/rockrobo/rrlog/rrlogmt.conf"

        # Set LOG_LEVEL=3
        if [ $ENABLE_OUCHER -eq 0 ]; then
            sed -i -E 's/(LOG_LEVEL=)([0-9]+)/\13/' "${IMG_DIR}/opt/rockrobo/rrlog/rrlog.conf"
        fi

        sed -i -E 's/(LOG_LEVEL=)([0-9]+)/\13/' "${IMG_DIR}/opt/rockrobo/rrlog/rrlogmt.conf"

        # Reduce logging of miio_client
        sed -i 's/-l 2/-l 0/' "${IMG_DIR}/opt/rockrobo/watchdog/ProcessList.conf"

        # Let the script cleanup logs
        sed -i 's/nice.*//' "${IMG_DIR}/opt/rockrobo/rrlog/tar_extra_file.sh"

        # Disable collecting device info to /dev/shm/misc.log
        sed -i '/^\#!\/bin\/bash$/a exit 0' "${IMG_DIR}/opt/rockrobo/rrlog/misc.sh"

        # Disable logging of 'top'
        sed -i '/^\#!\/bin\/bash$/a exit 0' "${IMG_DIR}/opt/rockrobo/rrlog/toprotation.sh"
        sed -i '/^\#!\/bin\/bash$/a exit 0' "${IMG_DIR}/opt/rockrobo/rrlog/topstop.sh"

        # Comment $IncludeConfig
        if [ -f "${IMG_DIR}/etc/rsyslog.conf" ]; then
            sed -Ei 's/^(\$IncludeConfig)/#&/' "${IMG_DIR}/etc/rsyslog.conf"
        fi

        # Disable cores
        if [ -f "${IMG_DIR}/etc/security/limits.conf" ]; then
            echo "* hard core 0" >> "${IMG_DIR}/etc/security/limits.conf"
            echo "* soft core 0" >> "${IMG_DIR}/etc/security/limits.conf"
        fi

        sed -i -E 's/ulimit -c unlimited/ulimit -c 0/' "${IMG_DIR}/opt/rockrobo/watchdog/rrwatchdoge.conf"
    fi
}
