# Globals
SSH__VM_PORT=""

# Options
SSH__CONNECT_TIMEOUT=5
SSH__VM_USERNAME="sm"
SSH__LOCAL_KEY_PATH="${SM_CONFIG_PATH}/ssh_keys"
SSH__LOCAL_KEY_FILE="${SSH__LOCAL_KEY_PATH}/id_rsa"


# TODO: Abort if an ssh kay pair was already created.
function ssh__create_local_key
{
    echo "ssh__create_key"
    if [ ! -d "${SSH__LOCAL_KEY_PATH}" ]; then
        mkdir -p "${SSH__LOCAL_KEY_PATH}"
    fi
    ssh-keygen -q -f "${SSH__LOCAL_KEY_FILE}" -N ""
}

# Check if an RSA key, which is used to login into the
# virtual maschines without a password, was already created.
function ssh__login_key_exists
{
    if [ ! -f "${SSH__LOCAL_KEY_FILE}" ]; then
        echo 0
    else
        echo 1
    fi
}

function ensure_local_key_exists
{
    if [ "$(ssh__login_key_exists)" = "0" ]; then
        ssh__create_local_key
    fi
}

# Copy one or more files to VM. If source file
# is a directory, the directory and all
# files/directories in it are also coppied
# recursively.
#
# Parameter:
# 1. Source (file/directory on local file system)
# 2. Target (path/filename in VM filesystem)
function ssh__send
{
    local VM_NAME="${1}"
    local SOURCE="${2}"
    local TARGET="${3}"

    #local RECURSIVE=""

    ssh__vm_name_2_ssh_port "${VM_NAME}"
    tar cf - "${SOURCE}" | ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i "${SSH__LOCAL_KEY_FILE}" "${SSH__VM_USERNAME}@localhost" tar xf -
    #tar cf - ${SOURCE} | ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i "${SSH__LOCAL_KEY_FILE}" ${SSH__VM_USERNAME}@127.0.0.1 tar xf -C ${TARGET} -
    #ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i "${SSH__LOCAL_KEY_FILE}" ${SSH__VM_USERNAME}@127.0.0.1 $*

    # if [ -d "${SOURCE}" ]; then
    #     RECURSIVE="-r"

    # fi
    # scp -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} ${RECURSIVE} -P 12201 ${SOURCE} ${SSH__VM_USERNAME}@127.0.0.1:${TARGET}
}

# Copy one or more files from the  VM to the local
# filesystem. If source file is a directory, the
# directory and all files/directories in it are
# also coppied recursively.
#
# Parameter:
# 1. Source (path/filename in VM filesystem)
# 2. Target (path/filename on local file system)
function ssh__receive
{
    local VM_NAME="${1}"
    local SOURCE="${2}"
    local TARGET="${3}"
    # shift 3
    # local USER_SSH_OPT

    ssh__vm_name_2_ssh_port "${VM_NAME}"
    ensure_local_key_exists
    scp -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -r -P ${SSH__VM_PORT} -i "${SSH__LOCAL_KEY_FILE}" -l ${SSH__VM_USERNAME} "localhost:${SOURCE}" "${TARGET}"
}

# Install a preshared key in a VM to allow
# login without passwort.
function ssh__install_key
{
    local VM_NAME="${1}"

    ssh__vm_name_2_ssh_port "${VM_NAME}"
    ensure_local_key_exists
    echo "Install key on target VM"
    ssh-copy-id -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i "${SSH__LOCAL_KEY_FILE}" "${SSH__VM_USERNAME}@localhost"
}

# Login into a VM.
function ssh__login
{
    local VM_NAME="${1}"

    ssh__vm_name_2_ssh_port "${VM_NAME}"
    ensure_local_key_exists
    ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -l ${SSH__VM_USERNAME} -i "${SSH__LOCAL_KEY_FILE}" "localhost"
}

# Run a command in the virtual maschine.
function ssh__exec
{
    local ERR
    local VM_NAME="${1}"
    shift 1 # Parameter 2-x is used as SSH command.

    ssh__vm_name_2_ssh_port "${VM_NAME}"
    ensure_local_key_exists
    #ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i "${SSH__LOCAL_KEY_FILE}" ${SSH__VM_USERNAME}@localhost $*
    ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -l ${SSH__VM_USERNAME} -i "${SSH__LOCAL_KEY_FILE}" "${SSH__VM_USERNAME}@locahost" $*
    ERR=${?}

    return ${ERR}
}

########################################################################
# private                                                              #
########################################################################

# Get the used TCP redirection port for the vm name.
function ssh__vm_name_2_ssh_port
{
    local LOCKFILE_NAME_PARTIAL
    local CURR_PORT
    local CURR_VM_NAME
    local VM_NAME="${1}"

    # TODO: extract {spice|ssh}__vm_name_2_ssh_port
    for LOCKFILE_NAME_PARTIAL in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock" |sed "s/\/tmp\/${PROGRAM_SHORT_NAME}__vde_vm__//g"); do
        CURR_VM_NAME=$(echo "${LOCKFILE_NAME_PARTIAL}" |sed "s/${PROGRAM_SHORT_NAME}__vde_vm__//g" |sed 's/.*__//g' |sed 's/\.lock//g')
        if [ "${CURR_VM_NAME}" = "${VM_NAME}" ]; then
            CURR_PORT=$(echo "${LOCKFILE_NAME_PARTIAL}" |sed 's/__.*\.lock//g')
            SSH__VM_PORT=${CURR_PORT}
            #echo "Found port: ${SSH__VM_PORT}"
            return
        fi
    done
    echo "VM is not running or has no SSH port listening."
    exit 1
    #ps aux |grep "nohub qemu" |grep hostfwd=tcp |grep "${} " |sed 's/\:\:/\$/g' |cut -d "$" -f 2 |sed 's/\-.*//g'
}
