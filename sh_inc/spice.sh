# Globals
SPICE__VM_PORT=""

# Options


# Connect to a running VM over spice.
#
# Parameter:
# 1. TCP port of spice server
function spice__login
{
    local VM_NAME="${1}"

    spice__vm_name_2_ssh_port "${VM_NAME}"
    remote-viewer spice://localhost:${SPICE__VM_PORT}
}

########################################################################
# private                                                              #
########################################################################

# Get the used TCP redirection port for the vm name.
function spice__vm_name_2_ssh_port
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
            SPICE__VM_PORT=${CURR_PORT}
            (( SPICE__VM_PORT += 1 ))
            return
        fi
    done
    echo "VM is not running or has no SSH port listening."
    exit 1
    #ps aux |grep "nohub qemu" |grep hostfwd=tcp |grep "${} " |sed 's/\:\:/\$/g' |cut -d "$" -f 2 |sed 's/\-.*//g'
}
