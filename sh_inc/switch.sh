# Create a new virtual switch.
function switch__start
{
    local VDE_SWITCH_NAME

    VDE_SWITCH_NAME=$1

    switch__status ${VDE_SWITCH_NAME}
    SWITCH_RUNNING=${?}
    if [ "${SWITCH_RUNNING}" != "1" ]; then
        echo "Switch ${VDE_SWITCH_NAME} is already running."
        exit 1
    fi

    vde_switch --daemon --sock /tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME} --mgmt /tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}.mgmt
    # TODO: Find a way to sync only the files we have created.
    sync
}

# Shutdown a switch
function switch__stop
{
    local VDE_SWITCH_NAME
    local SWITCH_RUNNING
    local SWITCH_PS_LINE
    local PID

    VDE_SWITCH_NAME=${1}

    switch__status ${VDE_SWITCH_NAME}
    SWITCH_RUNNING=${?}
    if [ "${SWITCH_RUNNING}" != "0" ]; then
        echo "Switch ${VDE_SWITCH_NAME} is not running."
        exit 1
    fi

    SWITCH_PS_LINE=$(ps aux |grep "vde" |grep "/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}")
    PID=$(echo ${SWITCH_PS_LINE} |sed 's/\ \ /\ /g' |sed 's/\ \ /\ /g' |sed 's/\ \ /\ /g' |cut -d " " -f 2)
    kill ${PID}
    # TODO: Find a way to sync only the files we have created.
    sync
}

# Login into the terminal of the switch.
function switch__console
{
    local VDE_SWITCH_NAME

    VDE_SWITCH_NAME=${1}
    unixterm /tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}.mgmt
}

# Return values:
# 0) switch is running
# 1) Switch is not running
function switch__status
{
    local PID_LINE_CNT=$(ps aux |grep "vde_switch" |grep -c "/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}")
    if [ "${PID_LINE_CNT}" != "1" ]; then
        return 1
    fi
    return 0
}

# Print a list of all running switches.
function switch__list
{
    local VDE_SWITCH_NAME

    for VDE_SWITCH_NAME in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__switch__*.mgmt"); do
        echo ${VDE_SWITCH_NAME} |sed "s|/tmp/${PROGRAM_SHORT_NAME}__switch__||g" |sed 's|\.mgmt||g'
    done
}

# Connect 2 VDE switch instances.
function switch__connect_to_switch
{
    exit 1
}
