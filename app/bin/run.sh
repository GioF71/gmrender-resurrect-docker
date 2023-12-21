#!/bin/bash

# error codes
# 1 invalid argument

function quote_if_needed() {
    var="${1}"
    opt_quote="\""
    if [[ "${var}" = \"* ]]; then
        opt_quote=""
    fi
    echo "${opt_quote}${var}${opt_quote}"
}

current_user_id=$(id -u)
echo "Current user id is [$current_user_id]"

if [[ "${current_user_id}" != "0" ]]; then
    echo "Not running as root, will not be able to create users" 
fi

BINARY=/usr/local/bin/gmediarender

CMD_LINE="$BINARY --logfile=stdout"

if [[ -n "${FRIENDLY_NAME}" ]]; then
    CMD_LINE="$CMD_LINE -f "$(quote_if_needed "${FRIENDLY_NAME}")
fi

if [[ -z "${UUID}" ]]; then
    echo "No uuid specified, try loading ..."
    UUID_FILE_PATH=/config/uuid.txt
    if [ -f $UUID_FILE_PATH ]; then
        echo "Found file with uuid ..."
        uuid=`cat $UUID_FILE_PATH`
        echo "UUID is ${uuid}"
        UUID="${uuid}"
    else
        echo "UUID file not found, generating ..."
        uuid=$(uuidgen)
        echo "UUID is [$uuid]"
        UUID="${uuid}"
        # write if possible
        if [ -w /config ]; then
            echo "${uuid}" > $UUID_FILE_PATH
            echo "Written generated [${uuid}] uuid."
        else
            echo "Config directory is not writable"
        fi
    fi
fi

if [[ -n "${UUID}" ]]; then
    CMD_LINE="$CMD_LINE -u "$(quote_if_needed "${UUID}")
fi

if [[ -z "${GSTOUT_AUDIOSINK}" ]] || [[ "${GSTOUT_AUDIOSINK^^}" == "ALSA" ]]; then
    CMD_LINE="$CMD_LINE --gstout-audiosink=alsasink"
elif [[ "${GSTOUT_AUDIOSINK^^}" == "PULSE" ]]; then
    CMD_LINE="$CMD_LINE --gstout-audiosink=pulsesink"
else
    echo "Invalid value for GSTOUT_AUDIOSINK=[${GSTOUT_AUDIOSINK}]"
    exit 1
fi

if [[ -z "${GSTOUT_AUDIODEVICE}" ]]; then
    CMD_LINE="$CMD_LINE --gstout-audiodevice=${GSTOUT_AUDIODEVICE}"
fi

echo "CMD_LINE=[${CMD_LINE}]"
eval $CMD_LINE
