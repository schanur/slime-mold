BIVALVIA_PATH="$(dirname $BASH_SOURCE)"


source ${BIVALVIA_PATH}/csv.sh
source ${BIVALVIA_PATH}/error.sh
source ${BIVALVIA_PATH}/require.sh


declare -A GL__CONFIG_LOADED

CONFIG_HOSTNAME=$(hostname)

# CONFIG_PATH=${DOTFILES_PATH}/config


# Add config file parameter to list of config files that have been
# loaded. This prevents us from loading config files multiple times.
function remember_loaded {
    not_implemented_error
}

# Returns 1 if a config file was already loaded. 0 otherwise.
function already_loaded {
    # TODO: Implement!
    echo "0"
}

function set_config_path {
    local NEW_CONFIG_PATH="${1}"

    require_directory "${NEW_CONFIG_PATH}"

    CONFIG_PATH="${NEW_CONFIG_PATH}"
}

# Replaces the hostname as profile subpath with a string provides as
# first parameter. This is currently for unit tests only. But maybe we
# will find other use cases later.
function set_config_hostname {
    local NEW_CONFIG_HOSTNAME=${1}

    CONFIG_HOSTNAME="${NEW_CONFIG_HOSTNAME}"
}

function profile_path {
    require_directory ${CONFIG_PATH}

    local HOSTNAME=${CONFIG_HOSTNAME}
    local PROFILE_PATH=${CONFIG_PATH}/profile/${HOSTNAME}

    echo ${PROFILE_PATH}
}

function global_path {
    require_directory ${CONFIG_PATH}

    local GLOBAL_PATH=${CONFIG_PATH}/global

    echo ${GLOBAL_PATH}
}

function profile_config_filename {
    local RELATIVE_CONFIG_FILENAME=${1}
    local PROFILE_PATH=$(profile_path)
    local ABSOLUTE_CONFIG_FILENAME="${PROFILE_PATH}/${RELATIVE_CONFIG_FILENAME}"

    echo ${ABSOLUTE_CONFIG_FILENAME}
}

function global_config_filename {
    local RELATIVE_CONFIG_FILENAME=${1}
    local GLOBAL_PATH=$(global_path)
    local ABSOLUTE_CONFIG_FILENAME="${GLOBAL_PATH}/${RELATIVE_CONFIG_FILENAME}"

    echo ${ABSOLUTE_CONFIG_FILENAME}
}

function profile_config_file_exists {
    local ABSOLUTE_CONFIG_FILENAME="$(profile_config_filename ${1})"
    local CONTAINS_CONFIG_FILE=0

    if [ -r ${ABSOLUTE_CONFIG_FILENAME} ]; then
        CONTAINS_CONFIG_FILE=1
    fi

    echo ${CONTAINS_CONFIG_FILE}
}

function global_config_file_exists {
    local ABSOLUTE_CONFIG_FILENAME="$(global_config_filename ${1})"
    local CONTAINS_CONFIG_FILE=0

    if [ -r ${ABSOLUTE_CONFIG_FILENAME} ]; then
        CONTAINS_CONFIG_FILE=1
    fi

    echo ${CONTAINS_CONFIG_FILE}
}

function config_file_exists {
    local RELATIVE_CONFIG_FILENAME=${1}
    local CONFIG_FILE_EXISTS=0

    if   [ $(profile_config_file_exists ${RELATIVE_CONFIG_FILENAME}) = "1" ]; then
        CONFIG_FILE_EXISTS=1
    elif [ $(global_config_file_exists  ${RELATIVE_CONFIG_FILENAME}) = "1" ]; then
        CONFIG_FILE_EXISTS=1
    fi

    echo ${CONFIG_FILE_EXISTS}
}

function absolute_config_file {
    local RELATIVE_CONFIG_FILENAME=${1}
    local ABSOLUTE_CONFIG_FILENAME=""

    if   [ $(profile_config_file_exists ${RELATIVE_CONFIG_FILENAME}) = "1" ]; then
        ABSOLUTE_CONFIG_FILENAME=$(profile_config_filename ${RELATIVE_CONFIG_FILENAME})
    elif [ $(global_config_file_exists  ${RELATIVE_CONFIG_FILENAME}) = "1" ]; then
        ABSOLUTE_CONFIG_FILENAME=$(global_config_filename  ${RELATIVE_CONFIG_FILENAME})
    else
        echo "Config file not found: ${RELATIVE_CONFIG_FILENAME}"
    fi

    require_file ${ABSOLUTE_CONFIG_FILENAME}

    echo ${ABSOLUTE_CONFIG_FILENAME}
}

function load_config_file {
    local RELATIVE_CONFIG_FILENAME=${1}
    local ABSOLUTE_CONFIG_FILENAME="$(absolute_config_file ${RELATIVE_CONFIG_FILENAME})"

    require_file ${ABSOLUTE_CONFIG_FILENAME}

    source ${ABSOLUTE_CONFIG_FILENAME}
}

function load_config_file_once {
    local RELATIVE_CONFIG_FILENAME=${1}
    local ABSOLUTE_CONFIG_FILENAME="$(absolute_config_file ${RELATIVE_CONFIG_FILENAME})"

    require_file ${ABSOLUTE_CONFIG_FILENAME}

    source ${ABSOLUTE_CONFIG_FILENAME}
}

function load_config_file_if_exists {
    local RELATIVE_CONFIG_FILENAME=${1}
    local ABSOLUTE_CONFIG_FILENAME="$(absolute_config_file ${RELATIVE_CONFIG_FILENAME})"

    if [ $(config_file_exists) = "1" ]; then
        source ${ABSOLUTE_CONFIG_FILENAME}
    fi
}

function load_config_file_if_exists_once {
    local RELATIVE_CONFIG_FILENAME=${1}
    local ABSOLUTE_CONFIG_FILENAME="$(absolute_config_file ${RELATIVE_CONFIG_FILENAME})"

    if [ $(config_file_exists) = "1" ]; then
        source ${ABSOLUTE_CONFIG_FILENAME}
    fi
}
