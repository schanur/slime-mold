# Create a new virtual switch.
function switch__start
{
    local VDE_SWITCH_NAME="${1}"
    local SWITCH_RUNNING

    SWITCH_RUNNING=$(switch__status "${VDE_SWITCH_NAME}")
    if [ "${SWITCH_RUNNING}" = "Online" ]; then
        echo "Switch ${VDE_SWITCH_NAME} is already running."
        exit 1
    fi
    vde_switch --daemon --sock "/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}" --mgmt "/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}.mgmt"
    # TODO: Find a way to sync only the files we have created.
    sync
}

# Shutdown a switch
function switch__stop
{
    local VDE_SWITCH_NAME="${1}"
    local SWITCH_RUNNING
    local SWITCH_PS_LINE
    local PID

    SWITCH_RUNNING=$(switch__status "${VDE_SWITCH_NAME}")
    if [ "${SWITCH_RUNNING}" = "Offline" ]; then
        echo "Switch ${VDE_SWITCH_NAME} is not running."
        exit 1
    fi

    SWITCH_PS_LINE=$(ps aux |grep "vde" |grep "/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}")
    PID=$(echo "${SWITCH_PS_LINE}" |sed 's/\ \ /\ /g' |sed 's/\ \ /\ /g' |sed 's/\ \ /\ /g' |cut -d " " -f 2)
    kill "${PID}"
    # TODO: Find a way to sync only the files we have created.
    sync
}

# Login into the terminal of the switch.
function switch__console
{
    local VDE_SWITCH_NAME="${1}"

    unixterm "/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}.mgmt"
}

function switch__online
{
    local SWITCH_NAME="${1}"
    # local STATUS_STR="$(echo -n "1")"
    local PID_LINE_CNT=$(ps aux | grep "vde_switch" | grep -c "/tmp/${PROGRAM_SHORT_NAME}__switch__${SWITCH_NAME}")
    if [ "${PID_LINE_CNT}" != "1" ]; then
        # echo "$(echo -n "0")"
        echo -n 0
    else
        echo -n 1
    fi

    # echo -n "${STATUS_STR}"

}

# Prints status string "Online" or "Offline"
function switch__status
{
    local SWITCH_NAME=${1}
    # local SWITCH_NAME="${VDE_SWITCH_NAME}"
    local STATUS_STR=""
    local SWITCH_ONLINE_RESULT="$(switch__online "${SWITCH_NAME}")"

    case ${SWITCH_ONLINE_RESULT} in
        0)
            STATUS_STR="Offline"
            ;;
        1)
            STATUS_STR="Online"
            ;;
        *)
            echo "Invalid switch status: > ${SWITCH_ONLINE_RESULT} <"
            exit 1
            ;;
    esac

    echo "${STATUS_STR}"
}

# Print a list of all running switches.
function switch__list
{
    local VDE_SWITCH_NAME

    for VDE_SWITCH_NAME in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__switch__*.mgmt"); do
        echo "${VDE_SWITCH_NAME}" | sed "s|/tmp/${PROGRAM_SHORT_NAME}__switch__||g" | sed 's|\.mgmt||g'
    done
}

# Connect 2 VDE switch instances.
function switch__connect_to_switch
{
    echo "Not implemented yet"
    exit 1
}
