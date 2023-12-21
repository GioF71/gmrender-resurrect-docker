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

create_audio_gid() {
    echo "  Adding $USER_NAME to group audio"
    if [ $(getent group $AUDIO_GID) ]; then
        echo "  Group with gid $AUDIO_GID already exists"
    else
        echo "  Creating group with gid $AUDIO_GID"
        groupadd -g $AUDIO_GID mpd-audio
    fi
    echo "  Adding $USER_NAME to gid $AUDIO_GID"
    AUDIO_GRP=$(getent group $AUDIO_GID | cut -d: -f1)
    echo "  gid $AUDIO_GID -> group $AUDIO_GRP"
    if id -nG "$USER_NAME" | grep -qw "$AUDIO_GRP"; then
        echo "  User $USER_NAME already belongs to group audio (GID ${AUDIO_GID})"
    else
        usermod -a -G $AUDIO_GRP $USER_NAME
        echo "  Successfully added $USER_NAME to group audio (GID ${AUDIO_GID})"
    fi
}

current_user_id=$(id -u)
echo "Current user id is [$current_user_id]"

if [[ "${current_user_id}" != "0" ]]; then
    echo "Not running as root, will not be able to create users" 
fi

DEFAULT_UID=1000
DEFAULT_GID=1000

DEFAULT_USER_NAME=gmrenderer-user
DEFAULT_GROUP_NAME=gmrenderer-user
DEFAULT_HOME_DIR=/home/$DEFAULT_USER_NAME

USER_NAME=$DEFAULT_USER_NAME
GROUP_NAME=$DEFAULT_GROUP_NAME
HOME_DIR=$DEFAULT_HOME_DIR

echo "USER_MODE=[${USER_MODE}]"

if [[ "${current_user_id}" == "0" && (! (${USER_MODE^^} == "NO" || ${USER_MODE^^} == "N")) ]]; then
    if [[ -z "${USER_MODE}" || "${USER_MODE^^}" == "YES" || "${USER_MODE^^}" == "Y" ]]; then
        USE_USER_MODE="Y"
        echo "User mode enabled"
        echo "Creating user ...";
        if [ -z "${PUID}" ]; then
            PUID=$DEFAULT_UID;
            echo "Setting default value for PUID: ["$PUID"]"
        fi
        if [ -z "${PGID}" ]; then
            PGID=$DEFAULT_GID;
            echo "Setting default value for PGID: ["$PGID"]"
        fi
        echo "Ensuring user with uid:[$PUID] gid:[$PGID] exists ...";
        ### create group if it does not exist
        if [ ! $(getent group $PGID) ]; then
            echo "Group with gid [$PGID] does not exist, creating..."
            groupadd -g $PGID $GROUP_NAME
            echo "Group [$GROUP_NAME] with gid [$PGID] created."
        else
            GROUP_NAME=$(getent group $PGID | cut -d: -f1)
            echo "Group with gid [$PGID] name [$GROUP_NAME] already exists."
        fi
        ### create user if it does not exist
        if [ ! $(getent passwd $PUID) ]; then
            echo "User with uid [$PUID] does not exist, creating..."
            useradd -g $PGID -u $PUID -M $USER_NAME
            echo "User [$USER_NAME] with uid [$PUID] created."
        else
            USER_NAME=$(getent passwd $PUID | cut -d: -f1)
            echo "user with uid [$PUID] name [$USER_NAME] already exists."
            HOME_DIR="/home/$USER_NAME"
        fi
        ### create home directory
        if [ ! -d "$HOME_DIR" ]; then
            echo "Home directory [$HOME_DIR] not found, creating."
            mkdir -p $HOME_DIR
            echo ". done."
        fi
        chown -R $PUID:$PGID $HOME_DIR
        ls -la $HOME_DIR -d
        ls -la $HOME_DIR

        if [[ -n "${AUDIO_GID}" ]]; then
            create_audio_gid
        fi

        #chown -R $USER_NAME:$GROUP_NAME /log
        #chown -R $USER_NAME:$GROUP_NAME /db
        #chown -R $USER_NAME:$GROUP_NAME /playlists

        ## PulseAudio
        PULSE_CLIENT_CONF="/etc/pulse/client.conf"
        echo "Creating pulseaudio configuration file $PULSE_CLIENT_CONF..."
        cp /app/assets/pulse-client-template.conf $PULSE_CLIENT_CONF
        sed -i 's/PUID/'"$PUID"'/g' $PULSE_CLIENT_CONF
        cat $PULSE_CLIENT_CONF
    else 
        echo "User mode disabled"
    fi
fi

if [[ -n "${ALSA_DEVICE}" ]]; then
    if [[ $current_user_id -eq 0 ]]; then
        if [ -f "/etc/asound.conf" ]; then
            echo "File /etc/asound.conf already exists!"
            exit 3
        else
            # TODO search
            echo "Creating /etc/asound.conf ..."
        fi
    else
        echo "Cannot set alsa device if not running as root"
        exit 2
    fi
fi

BINARY=/usr/local/bin/gmediarender

#CMD_LINE="$BINARY --logfile=stdout"
CMD_LINE="$BINARY"

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

if [[ -n "${GSTOUT_AUDIODEVICE}" ]]; then
    CMD_LINE="$CMD_LINE --gstout-audiodevice="$(quote_if_needed "${GSTOUT_AUDIODEVICE}")
fi

echo "CMD_LINE=[${CMD_LINE}]"

if [[ $current_user_id -ne 0 ]]; then
    eval $CMD_LINE
else
    su - $USER_NAME -c "$CMD_LINE"
fi
