# Globals
QMP__VM_PORT=""
QMP_CONSOLE__VM_PORT=""


# Connect to VM over QMP and execute a QMP command.
# Parameter:
# 1) VM name
# 2) QMP Command
#
# Tested commands: system_powerdown
function qemu__qmp_execute
{
    local VM_NAME="${1}"
    local QMP_COMMAND="${2}"

    qemu__vm_name_2_qmp_port "${VM_NAME}"

    echo "{ \"execute\": \"qmp_capabilities\" }{ \"execute\": \"${QMP_COMMAND}\" }" | nc localhost ${QMP__VM_PORT}
}


function qemu__qmp_console
{
    local VM_NAME="${1}"

    qemu__vm_name_2_qmp_console_port "${VM_NAME}"

    telnet localhost ${QMP_CONSOLE__VM_PORT}
}


########################################################################
# private                                                              #
########################################################################

# Get the used TCP redirection port for the vm name.
function qemu__vm_name_2_qmp_port
{
    local LOCKFILE_NAME_PARTIAL
    local CURR_PORT
    local CURR_VM_NAME
    local VM_NAME="${1}"

    # TODO: extract {spice|ssh|qmp}__vm_name_2_XXX_port
    for LOCKFILE_NAME_PARTIAL in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock" |sed "s/\/tmp\/${PROGRAM_SHORT_NAME}__vde_vm__//g"); do
        CURR_VM_NAME=$( echo "${LOCKFILE_NAME_PARTIAL}" |sed "s/${PROGRAM_SHORT_NAME}__vde_vm__//g" |sed 's/.*__//g' |sed 's/\.lock//g')
        if [ "${CURR_VM_NAME}" = "${VM_NAME}" ]; then
            CURR_PORT=$(echo "${LOCKFILE_NAME_PARTIAL}" |sed 's/__.*\.lock//g')
            QMP__VM_PORT=${CURR_PORT}
            (( QMP__VM_PORT += 2 ))
            return
        fi
    done
    echo "VM is not running or has no QEMU QMP port listening."
    exit 1
}

# Get the used TCP redirection port for the vm name.
function qemu__vm_name_2_qmp_console_port
{
    local LOCKFILE_NAME_PARTIAL
    local CURR_PORT
    local CURR_VM_NAME
    local VM_NAME="${1}"

    # TODO: extract {spice|ssh|qmp}__vm_name_2_XXX_port
    for LOCKFILE_NAME_PARTIAL in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock" |sed "s/\/tmp\/${PROGRAM_SHORT_NAME}__vde_vm__//g"); do
        CURR_VM_NAME=$( echo "${LOCKFILE_NAME_PARTIAL}" |sed "s/${PROGRAM_SHORT_NAME}__vde_vm__//g" |sed 's/.*__//g' |sed 's/\.lock//g')
        if [ "${CURR_VM_NAME}" = "${VM_NAME}" ]; then
            CURR_PORT=$(echo "${LOCKFILE_NAME_PARTIAL}" |sed 's/__.*\.lock//g')
            QMP_CONSOLE__VM_PORT=${CURR_PORT}
            (( QMP_CONSOLE__VM_PORT += 3 ))
            return
        fi
    done
    echo "VM is not running or has no QEMU QMP port listening."
    exit 1
}
