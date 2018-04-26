# We can only set one trap function for received signals.
# This variable is extended by a filename for every
# created lockfile which is then used in the trap command.
LF__LOCKFILE_LIST="" # Used by lf__create_lockfile(), lf__destroy_lockfile_list()

LF__LOCKFILE_NAME="" # Used by lf__lockfile_name_*()

# function lf__vm_lockfile_name()
# {
#     local VM_NAME=${1}

#     LF__LOCKFILE_NAME=/tmp/${PROGRAM_SHORT_NAME}__vde_vm_name__${VM_NAME}.lock
# }


# Create the filename of the lockfile by 2 parameters.
# 1. SSH port
# 2. VM name
function lf__lockfile_name__virtual_machine
{
    local SSH_REDIRECT_PORT=${1}
    local VM_NAME="${2}"

    LF__LOCKFILE_NAME="/tmp/${PROGRAM_SHORT_NAME}__vde_vm__${SSH_REDIRECT_PORT}__${VM_NAME}.lock"
}

# Create a lockfile with the path/name
# of the parameter $1.
function lf__create_lockfile
{
    local ERR
    local LOCKFILE_NAME=$*

    lockfile -r 0 "${LOCKFILE_NAME}"
    ERR=$?
    if [ "${ERR}" != "0" ]; then
        echo "Application is already running or lockfile was not deleted after last run." >&2
        exit 1
    else
        echo "Create lockfile \"${LOCKFILE_NAME}\""
    fi
    LF__LOCKFILE_LIST="${LF__LOCKFILE_LIST} ${LOCKFILE_NAME}"
    #trap "rm -f ${LF__LOCKFILE_LIST}; exit" INT TERM EXIT

    # If the program crashed for any particular reason, remove all
    # lockfiles.
    trap "lf__destroy_lockfile_list" INT TERM EXIT
}

# Delete the lockfile with the path/name
# of the parameter $1.
function lf__destroy_lockfile
{
    LOCKFILE_NAME="${1}"
    if [ -f "${LOCKFILE_NAME}" ]; then
        echo "Destroy lockfile \"${LOCKFILE_NAME}\""
        rm -f "${LOCKFILE_NAME}"
#    else
#        echo "Cannot destroy lockfile \"$1\""
#        exit 1
    fi
}

function lf__destroy_lockfile_list
{
    local LOCKFILE

    echo "Received signal"
    for LOCKFILE in ${LF__LOCKFILE_LIST}; do
        true
        #lf__destroy_lockfile ${LOCKFILE}
    done
    exit 0
}

# function lf__lock_global()
# {
#     exit 1
# }

# function lf__unlock_global()
# {
#     exit 1
# }

# function lf__port_in_use()
# {
#     local LOCKFILE_NAME_PARTIAL
#     local CURR_PORT
#     local CURR_VM_NAME
#     local VM_NAME=${1}
#     for LOCKFILE_NAME_PARTIAL in $(find /tmp -name "${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock" |sed 's/${PROGRAM_SHORT_NAME}__vde_vm__//g |'); do
#         CURR_VM_NAME = $(echo ${LOCKFILE_NAME_PARTIAL} |sed 's/${PROGRAM_SHORT_NAME}__vde_vm__//g' |sed 's/.*__//g' |sed 's/\.lock//g'
#         if [ "${CURR_VM_NAME}" = "${VM_NAME}" ]; then
#             CURR_PORT = $(echo ${LOCKFILE_NAME_PARTIAL} |sed 's/__.*\.lock//g')
#             break
#         fi
#     done
#     exit 1
# }


# function check_lockfile_location_valid() {
#     local LOCKFILE=$*
#     local REALPATH=$(readlink -f ${LOCKFILE})
#     if []
# }



########################################################################
# CRAP                                                                 #
########################################################################


# # Create a lockfile with the path/name
# # of the parameter $1.
# function create_lockfile() {
#     local LOCKFILE=$*
#     echo ${LOCKFILE}
#     if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
#         # Lockfile exists.
#         echo sdfff
#         echo "Application is allready running or lockfile was not deleted after last run." >&2
#         echo "Lockfile: ${LOCKFILE}" >&2
#         exit 1
#     fi
#     echo 123234

#     # make sure the lockfile is removed when we exit and then claim it
#     #trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT

#     echo $$ > ${LOCKFILE}
# }

# # Delete the lockfile with the path/name
# # of the parameter $1.
# function destroy_lockfile() {
#     rm -f $*
# }

