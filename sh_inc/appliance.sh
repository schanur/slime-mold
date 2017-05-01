declare -a APPLIANCE__MYC_CMD_LIST
APPLIANCE__MYC_CMD_LIST_LENGTH=0

declare -a APPLIANCE__TEST_CMD_LIST
APPLIANCE__TEST_CMD_LIST_LENGTH=0

declare -a APPLIANCE__ARRAY
APPLIANCE__ARRAY_LENGTH=0

function appliance__start
{
    local APPLIANCE_FILE=${1}
    local APPLIANCE_FILE_MALFORMED
    local APPLIANCE_NAME=$(basename ${APPLIANCE_FILE})

    echo "appliance__start: ${APPLIANCE_NAME}"

    appliance__check_file_syntax ${APPLIANCE_FILE}

    # Run appliance file.
    . ${SCRIPT_DIR}/${APPLIANCE_FILE}

    appliance__get_all_online

    #appliance__read_file
    exit 1

}

function appliance__stop
{
    echo "appliance__stop"
    exit 1
}

#function appliance__()

function appliance__read_file_sections
{
    local LINE

    exit 1
}

#
function appliance__check_file_syntax
{
    local APPLIANCE_FILE=${1}

    if [ ! -r "${APPLIANCE_FILE}" ]; then
        echo "Cannot read appliance file."
        exit 1
    fi

    bash -n ${APPLIANCE_FILE}
    APPLIANCE_FILE_MALFORMED=$?
    if [ "${APPLIANCE_FILE_MALFORMED}"  != "0" ]; then
        echo "Appliance file malformed."
        echo "Abort."
        exit 1
    fi
}

#
function appliance__watchdog
{
    echo "appliance__watchdog"
    exit 1
}

# Check if VM is online. If it is not
# online, start the VM and block until
# the VM is online.
function appliance__get_vm_online
{
    local VM_NAME

    VM_NAME=$(vm__image_file_2_vm_name ${IMAGE_FILE})

    echo "appliance__get_vm_online"
}

# Stop the VM and block until it is
# offline.
function appliance__get_vm_offline
{
    echo "appliance__get_vm_offline"
    exit 1
}

function appliance__get_all_online
{

    echo "appliance__get_all_online"
    #array2="${array1[@]}"
    #APPLIANCE__TEST_CMD_LIST="${SETUP[@]}"
    APPLIANCE__TEST_CMD_LIST=( "${SETUP[@]}" )
    appliance__list_2_array
    exit 1
}

function appliance__list_2_array
{
    echo "appliance__list_2_array"
    #local LIST=${*}
    local LIST_CMD_CNT
    local LIST_CMD_NO
    #APPLIANCE__ARRAY_LENGTH=0

    LIST_CMD_CNT=${#APPLIANCE__TEST_CMD_LIST[@]}
    #echo "list: ${APPLIANCE__TEST_CMD_LIST[1]}"
    #exit 1

    (( --LIST_CMD_CNT ))
    for LIST_CMD_NO in $(seq 0 ${LIST_CMD_CNT}); do
        echo ${APPLIANCE__TEST_CMD_LIST[${LIST_CMD_NO}]}
        echo
        #echo ${CMD}
    done

    APPLIANCE__ARRAY_LENGTH

    exit 1
}

# With the functions below the comment, the syntax of the appliance
# files are compatible with bash sytax. Therefore we can execute
# the appliance files directly.

function section
{
    echo "section found: $*"
}

# TODO: What is this about???
function myc
{
    local ERR
    local CMD=${*}

    parse_cmd ${CMD}
    ERR=${?}
    if [ "${ERR}" != "0" ]; then
        echo
        echo "Command failed: ${CMD}"
        echo "Abort."
        exit 1
    fi
}

