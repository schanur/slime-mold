# Globals
SSH__VM_PORT=""

SSH__VM_USERNAME=$(whoami)

# Options
SSH__CONNECT_TIMEOUT=5

# TODO: Abort if an ssh kay pair was already created.
function ssh__create_key
{
    echo "ssh__create_key"
    ssh-keygen -q -f ssh_conf/id_rsa -N ""
}

# Check if an RSA key, which is used to login into the
# virtual maschines without a password, was already created.
function ssh__login_key_exists
{
    if [ ! -f ssh_conf/id_rsa ]; then
        return 0
    fi
    return 1
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
    local VM_NAME=${1}
    local SOURCE=${2}
    local TARGET=${3}

    VM_NAME=$1
    #local RECURSIVE=""

    ssh__vm_name_2_ssh_port ${VM_NAME}
    tar cf - ${SOURCE} | ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i ssh_conf/id_rsa ${SSH__VM_USERNAME}@127.0.0.1 tar xf -
    #tar cf - ${SOURCE} | ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i ssh_conf/id_rsa ${SSH__VM_USERNAME}@127.0.0.1 tar xf -C ${TARGET} -
    #ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i ssh_conf/id_rsa ${SSH__VM_USERNAME}@127.0.0.1 $*

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
    local VM_NAME=${1}
    local SOURCE=${2}
    local TARGET=${3}

    VM_NAME=$1

    scp -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -r -P 12201 ${SSH__VM_USERNAME}@127.0.0.1:${SOURCE} ${TARGET}
}

# Install a preshared key in a VM to allow
# login without passwort.
function ssh__install_key
{
    local VM_NAME

    VM_NAME=$1
    ssh__vm_name_2_ssh_port ${VM_NAME}
    if [ "$(ssh__login_key_exists)" = "0" ]; then
        ssh_create_key
    fi
    echo "Install key on target VM"
    scp -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -P ${SSH__VM_PORT} ssh_conf/id_rsa.pub ${SSH__VM_USERNAME}@127.0.0.1:.ssh/authorized_keys exit
}

# Login into a VM.
function ssh__login
{
    local VM_NAME

    VM_NAME=$1
    ssh__vm_name_2_ssh_port ${VM_NAME}
    ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i ssh_conf/id_rsa ${SSH__VM_USERNAME}@127.0.0.1
}

# Run a command in the virtual maschine.
function ssh__exec
{
    local ERR
    local VM_NAME

    VM_NAME=$1
    shift 1 # Parameter 2-x is used as SSH command.

    ssh__vm_name_2_ssh_port ${VM_NAME}
    #ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i ssh_conf/id_rsa ${SSH__VM_USERNAME}@127.0.0.1 $*
    ssh -o ConnectTimeout=${SSH__CONNECT_TIMEOUT} -p ${SSH__VM_PORT} -i ssh_conf/id_rsa ${SSH__VM_USERNAME}@127.0.0.1 $*
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
    local VM_NAME=${1}

    for LOCKFILE_NAME_PARTIAL in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock" |sed 's/\/tmp\/${PROGRAM_SHORT_NAME}__vde_vm__//g'); do
        CURR_VM_NAME=$(echo ${LOCKFILE_NAME_PARTIAL} |sed 's/${PROGRAM_SHORT_NAME}__vde_vm__//g' |sed 's/.*__//g' |sed 's/\.lock//g')
        if [ "${CURR_VM_NAME}" = "${VM_NAME}" ]; then
            CURR_PORT=$(echo ${LOCKFILE_NAME_PARTIAL} |sed 's/__.*\.lock//g')
            SSH__VM_PORT=${CURR_PORT}
            #echo "Found port: ${SSH__VM_PORT}"
            return
        fi
    done
    echo "VM is not running or has no SSH port listening."
    exit 1
    #ps aux |grep "nohub qemu" |grep hostfwd=tcp |grep "${} " |sed 's/\:\:/\$/g' |cut -d "$" -f 2 |sed 's/\-.*//g'
}
