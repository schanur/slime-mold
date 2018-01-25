# Globals
#VM__RUNNING_VM_LIST=""
VM__HW_ACCELERATION=""
VM__FOUND_PID=""
VM__FOUND_FREE_PORT_GROUP=""
VM__FOUND_FREE_IP=""
VM__FOUND_FREE_VLAN=""
VM__UNIQUE_MAC_ADDR=""
VM__USED_IP_BYTE_LIST=""
VM__USED_VLAN_LIST=""

VM__HUB_IMAGE_LIST_DOWNLOAD_URL=

VM__INCOMPLETE_IMAGE_CACHE_PATH="${HOME}/.cache/slime-mold/prebuild/incomplete"
VM__READY_IMAGE_CACHE_PATH="${HOME}/.cache/slime-mold/prebuild/ready"

VM__PREBUILD_DOWNLOAD_LIST_FILE="${SCRIPT_PATH}/data/vm_creation/download_prebuild"


# Check if OS has hardware virtualization
# support. If OS supports KVM, return 1.
# Return 0 otherwise.
function vm__check_kvm_extension
{
    local CPU_FLAGS_FOUND

    VM__HW_ACCELERATION=1

    # Check required flags in the CPU extension list.
    CPU_FLAGS_FOUND=$(cat /proc/cpuinfo |grep vme |grep -c vmx)
    if [ "${CPU_FLAGS_FOUND}" = "0" ]; then
        echo "Hardware acceleration check: CPU extensions not found."
    else
        # /dev/kvm is accessible for the current user?
        # (separate tests for read/write permission)
        if [ ! -r "/dev/kvm" ]; then
            echo "Hardware acceleration check: User has no permission to start hardware accelerated quests. Read permission on /dev/kvm missing"
        else
            if [ ! -w "/dev/kvm" ]; then
                echo "Hardware acceleration check: User has no permission to start hardware accelerated quests. Write permission on /dev/kvm missing"
            else
                # Everything is fine.
                VM__HW_ACCELERATION=1
            fi
        fi
    fi

    if [ "${VM__HW_ACCELERATION}" = "0" ]; then
        echo "No usable configuration for hardware acceleration found. Software emulation is used instead."
    fi
}

# Find a free TCP port group (4 continuous ports) in the range of 12201 - 12299 on the host.
# It returns the first port number of the group.
function vm__find_free_tcp_port_group
{
    local PORT
    local PORT_FREE
    local PORT_IN_USE
    local USED_PORT
    local FREE_PORT_FOUND
    local FOUND_IN_LOCKFILE

    local PORT_GROUP_END
    local PORT_GROUP_SIZE=4

    FREE_PORT_FOUND=0

    # Get a list of all listening ports from the OS.
    PORTS_IN_USE=$(netstat -nl --protocol=inet |grep LISTEN |sed 's/ \+\ /\ /g' |cut -d " " -f 4 |sed 's/.*://g' |grep "122" || true)
    echo "Ports in use: ${PORTS_IN_USE}"
    for PORT_GROUP_START in $(seq 12200 ${PORT_GROUP_SIZE} 12280); do
        echo "PORT_GROUP_START: ${PORT_GROUP_START}"
        # Skip testing ports that are marked as already listening.
        PORT_IN_USE=0
        ((PORT_GROUP_END=(PORT_GROUP_START+PORT_GROUP_SIZE)-1))
        for PORT in $(seq ${PORT_GROUP_START} ${PORT_GROUP_END}); do
            case $(echo "${PORTS_IN_USE}" | grep -c ${PORT}) in
                0)
                    continue
                    ;;
                1)
                    PORT_IN_USE=1
                    break
                    ;;
                *)
                    echo "Parse error while finding free port. Abort!"
                    exit 1
                    ;;
            esac
        done
        if [ ${PORT_IN_USE} -eq 1 ]; then
            continue
        fi

        # We found a free port by looking into the netstat table.
        # We also check that the port doesn't occur in the lockfiles.
        # Maybe this is redundant.
        FOUND_IN_LOCKFILE=$(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__${PORT_GROUP_START}__*.lock" |wc -l)
        if [ "${FOUND_IN_LOCKFILE}" != "0" ]; then
            echo "Warning! TCP port ${PORT_GROUP_START} is not listening, but lockfile exists."
            continue
        fi
        VM__FOUND_FREE_PORT_GROUP=${PORT_GROUP_START}
        return
    done
    echo "All TCP ports in the range 12201-12299 are in use"
    exit 1
}

# Generate a list of IPs used by the QEMU slirp
# network backend.
function vm__used_ip_list
{
    local IP
    local IFS_RESTORE=${IFS}
    IFS=$(echo -e "\n")
    VM__USED_IP_LIST=""
    while read IP; do
        if [ "${IP}" = "" ]; then
            continue
        fi
        VM__USED_IP_BYTE_LIST="${VM__USED_IP_BYTE_LIST} ${IP}"
    done <<< $(ps aux |grep "qemu" |grep "-net user,net=10.0.2.0/24" | grep "dhcpstart=10.0.2." |sed 's/.*dhcpstart=10.0.2.//g' |sed 's/,.*//g')
    IFS=${IFS_RESTORE}
}

# Find a free IP in the range 10.0.2.20-10.0.2.254.
function vm__find_free_ip
{
    local IP_BYTE
    local USED_IP_BYTE
    local IP_IN_USE
    local QEMU_INSTANCE
    local LINE

    vm__used_ip_list
    for IP_BYTE in $(seq 20 254); do
        IP_IN_USE=0
        for USED_IP_BYTE in ${VM__USED_IP_BYTE_LIST}; do
            if [ ${USED_IP_BYTE} = ${IP_BYTE} ]; then
                IP_IN_USE=1
                break
            fi
        done
        if [ ${IP_IN_USE} = "0" ]; then
            VM__FOUND_FREE_IP="10.0.2.${IP_BYTE}"
            return
        fi
    done
    echo "All IPs in the range 10.0.2.20-10.0.2.254 are in use. Abort."
    exit 1
}

# Generate a list of VLAN ids used by the QEMU slirp
# network backend.
function vm__used_vlan_list
{
    local VLAN
    local IFS_RESTORE=${IFS}

    IFS=$(echo -e "\n")
    VM__USED_VLAN_LIST=""
    while read VLAN; do
        if [ "${VLAN}" = "" ]; then
            continue
        fi
        VM__USED_VLAN_LIST="${VM__USED_VLAN_LIST} ${VLAN}"
    done <<< $(ps aux |grep "qemu" |grep "-net user,net=10.0.2.0/24" | grep "dhcpstart=10.0.2." |sed 's/.*vlan=//g' |sed 's/\ .*//g')
    IFS=${IFS_RESTORE}
}

# Find a free VLAN in the range 1-12.
function vm__find_free_vlan
{
    local VLAN
    local USED_VLAN
    local VLAN_IN_USE
    local QEMU_INSTANCE
    local LINE

    vm__used_vlan_list
    for VLAN in $(seq 1 12); do
        VLAN_IN_USE=0
        for USED_VLAN in ${VM__USED_VLAN_LIST}; do
            if [ ${USED_VLAN} = ${VLAN} ]; then
                VLAN_IN_USE=1
                break
            fi
        done
        if [ ${VLAN_IN_USE} = "0" ]; then
            VM__FOUND_FREE_VLAN="${VLAN}"
            return
        fi
    done
    echo "All VLANs in the range 1-12 are in use. Abort."
    exit 1
}


# Generate a unique MAC address based on the VM name, where the same
# VM name will always generate the same MAC address.
#
function vm__unique_mac
{
    local VM_NAME="${1}"
    local SALT="${2}"
    local PREFIX="00:80:AD"
    local HASH

    HASH=$(echo "${VM_NAME}${SALT}" |sha512sum)

    VM__UNIQUE_MAC_ADDR="${PREFIX}:${HASH:0:2}:${HASH:2:2}:${HASH:4:2}"
}

# Start a VM in a non blocking way.
function vm__start
{
    local IMAGE_FILE="${1}"
    local VDE_SWITCH_NAME="${2}"
    local VDE_NIC_MAC_ADDR
    local UMODE_NIC_MAC_ADDR
    local VM_NAME
    local VM_RUNNING
    local VM_SSH_PORT
    local VM_SPICE_PORT
    local VM_IP
    local VM_VLAN
    local LOCKFILE_VM
    local HW_ACCELERATION

    VM_NAME=$(vm__image_file_2_vm_name "${IMAGE_FILE}")

    VM_RUNNING=$(vm__vm_running "${VM_NAME}")
    if [ "${VM_RUNNING}" = "1" ]; then
        echo "VM is already running"
        exit 1
    fi

    vm__unique_mac "${VM_NAME}" "umode"
    UMODE_NIC_MAC_ADDR=${VM__UNIQUE_MAC_ADDR}

    vm__unique_mac ${VM_NAME} "vde"
    VDE_NIC_MAC_ADDR=${VM__UNIQUE_MAC_ADDR}

    vm__find_free_tcp_port_group
    VM_SSH_PORT=${VM__FOUND_FREE_PORT_GROUP}
    VM_SPICE_PORT=$(( VM__FOUND_FREE_PORT_GROUP + 1 ))

    vm__find_free_ip
    VM_IP=${VM__FOUND_FREE_IP}

    # FIXME: vm__find_free call prints value to stdout
    vm__find_free_vlan
    VM_VLAN=${VM__FOUND_FREE_VLAN}
    echo ${VM_VLAN}

    lf__lockfile_name__virtual_machine ${VM_SSH_PORT} "${VM_NAME}"
    LOCKFILE_VM="${LF__LOCKFILE_NAME}"

    vm__check_kvm_extension
    HW_ACCELERATION=${VM__HW_ACCELERATION}

    echo "PROGRAM_SHORT_NAME: ${PROGRAM_SHORT_NAME}"
    echo "VM_RUNNING:         ${VM_RUNNING}"
    echo "IMAGE_FILE:         ${IMAGE_FILE}"
    echo "VM_SSH_PORT:        ${VM_SSH_PORT}"
    echo "VM_SPICE_PORT:      ${VM_SPICE_PORT}"
    echo "UMODE_NIC_MAC_ADDR: ${UMODE_NIC_MAC_ADDR}"
    echo "VDE_NIC_MAC_ADDR:   ${VDE_NIC_MAC_ADDR}"
    echo "VDE_SWITCH_NAME:    ${VDE_SWITCH_NAME}"
    echo "LOCKFILE_VM:        ${LOCKFILE_VM}"
    echo "HW_ACCELERATION:    ${HW_ACCELERATION}"
    echo "VM_IP:              ${VM_IP}"
    echo "VM_VLAN:            ${VM_VLAN}"

    #  ${PROGRAM_SHORT_NAME} ${IMAGE_FILE} ${VM_SSH_PORT} ${UMODE_NIC_MAC_ADDR} ${VDE_NIC_MAC_ADDR} ${VDE_SWITCH_NAME} ${LOCKFILE_VM} ${HW_ACCELERATION} ${VM_NAME} ${VM_IP} ${VM_VLAN}

    nohup bash $(dirname $(which sm))/sh_inc/async_qemu.sh \
          "${PROGRAM_SHORT_NAME}" \
          "${IMAGE_FILE}" \
          "${VM_SSH_PORT}" \
          "${VM_SPICE_PORT}" \
          "${UMODE_NIC_MAC_ADDR}" \
          "${VDE_NIC_MAC_ADDR}" \
          "${VDE_SWITCH_NAME}" \
          "${LOCKFILE_VM}" \
          "${HW_ACCELERATION}" \
          "${VM_NAME}" \
          "${VM_IP}" \
          "${VM_VLAN}" \
          > "${LOCKFILE_VM}.log" 2>&1 &
}

# Stop the VM by sending the "halt" command over SSH.
function vm__stop
{
    local VM_NAME="${1}"

    ssh__exec "${VM_NAME}" halt
}

# Stop the VM by sending SIGKILL to the qemu process.
function vm__kill
{
    local VM_NAME="${1}"

    ssh__exec "${VM_NAME}" halt
}

# Stop the VM by sending the "halt" command over SSH. The function
# blocks until the VM has shut down.  TODO: It still blocks.
function vm__stop_blocking
{
    local VM_NAME="${1}"

    vm__stop "${VM_NAME}"
}



# Check if the VM name occurs in a lockfile.
# Echos values:
# 1 if VM is running.
# 0 if VM is not running.
function vm__vm_running
{
    local LOCKFILE_NAME_PARTIAL
    local MATCH_CNT
    local VM_NAME="${1}"

    MATCH_CNT=0
    for LOCKFILE_NAME_PARTIAL in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock"); do
        (( MATCH_CNT += 1 ))
    done

    if   [[ "${MATCH_CNT}" = "1" ]]; then
        echo 1
    elif [[ "${MATCH_CNT}" = "0" ]]; then
        echo 0
    else
        echo "Error: More than one lockfile found for \"${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock\""
        exit 1
    fi
}

# Prints a formated table with VM name and download URL.
function vm__list_prebuild
{
    cat "${VM__PREBUILD_DOWNLOAD_LIST_FILE}" | grep -v "^\ *#" | tr -s ' ' | cut -f 1,2 -d ' ' | column -t
}

function vm__download_prebuild_to_cache
{
    local URL="${1}"
    # local TEMPORARY_IMAGE_FILENAME="${2}"
    local BASE32_URL="$(echo ${URL} | base32 -w 0)"
    local PROTOCOL=$(echo ${URL} | sed -e 's/:.*//g')
    local REMOTE_BASENAME="$(echo ${URL} | sed -e 's|^./||g')"
    local TEMPORARY_IMAGE_FILENAME="${VM__INCOMPLETE_IMAGE_CACHE_PATH}/${BASE32_URL}"
    local READY_IMAGE_FILENAME="${VM__READY_IMAGE_CACHE_PATH}/${BASE32_URL}"
    local DOWNLOAD_COMPLETE=0

    echo "URL:                         ${URL}"
    echo "BASE32_URL:                  ${BASE32_URL}"
    echo "PROTOCOL:                    ${PROTOCOL}"
    echo "REMOTE_BASENAME:             ${REMOTE_BASENAME}"
    echo "TEMPORARY_IMAGE_FILENAME:    ${TEMPORARY_IMAGE_FILENAME}"
    echo "READY_IMAGE_FILENAME:        ${READY_IMAGE_FILENAME}"

    if [ ! -d "${VM__INCOMPLETE_IMAGE_CACHE_PATH}" ]; then
        echo "Create cache path for incomplete files: ${VM__INCOMPLETE_IMAGE_CACHE_PATH}"
        mkdir -p "${VM__INCOMPLETE_IMAGE_CACHE_PATH}"
    fi
    if [ ! -d "${VM__READY_IMAGE_CACHE_PATH}" ]; then
        echo "Create cache path for completed files:  ${VM__READY_IMAGE_CACHE_PATH}"
        mkdir -p "${VM__READY_IMAGE_CACHE_PATH}"
    fi

    case ${PROTOCOL} in
        'scp')
            # Convert a scp URI to the 3 parameters needed by the scp command.
            declare -a URI_PARTS=($(echo ${URL} | sed -e 's|scp://||g' | sed -e 's|:|\ |g' | sed 's|/|\ |'))
            local SCP_HOSTNAME=${URI_PARTS[0]}
            local SCP_PORT SCP_FILENAME
            case ${#URI_PARTS[@]} in
                2)
                    SCP_PORT="22"
                    SCP_FILENAME=${URI_PARTS[1]}
                    ;;
                3)
                    SCP_PORT=${URI_PARTS[1]}
                    SCP_FILENAME=${URI_PARTS[2]}
                    ;;
            esac
            local SCP_HOSTNAME=${URI_PARTS[0]}
            scp -P ${SCP_PORT} "${SCP_HOSTNAME}:/${SCP_FILENAME}" "${TEMPORARY_IMAGE_FILENAME}" && DOWNLOAD_COMPLETE=1
            #echo scp -B -P ${SCP_PORT} "${SCP_HOSTNAME}:/${SCP_FILENAME} ${VM__INCOMPLETE_IMAGE_CACHE_PATH}/" && DOWNLOAD_COMPLETE=1
            ;;
        'https')
            wget -O "${TEMPORARY_IMAGE_FILENAME}" "${URL}" && DOWNLOAD_COMPLETE=1
            ;;
        *)
            echo "Protocol not supported: ${PROTOCOL}"
            exit 1
            ;;
    esac

    if [ ${DOWNLOAD_COMPLETE} -eq 1 ]; then
        echo "Download successful."
        mv "${TEMPORARY_IMAGE_FILENAME}" "${READY_IMAGE_FILENAME}"
    fi
}

#
function vm__file_checksum
{
    local FILENAME="${1}"
    local CHECKSUM_TYPE="${2}"

    case ${CHECKSUM_TYPE} in
        'sha256')
            sha256sum "${FILENAME}" | cut -f 1 -d ' '
            ;;
        'sha512')
            sha512sum "${FILENAME}" | cut -f 1 -d ' '
            ;;
        *)
            exit 1
            ;;
    esac
}

function vm__create_from_prebuild
{
    local VM_NAME="${1}"
    local PREBUILD_VM_NAME="${2}"
    local DOWNLOAD_LINE=$(cat "${VM__PREBUILD_DOWNLOAD_LIST_FILE}" | grep -v '^\ *#' | tr -s ' ' | egrep "${PREBUILD_VM_NAME}")
    local URL="$(echo ${DOWNLOAD_LINE} | cut -f 2 -d ' ')"
    local FILE_SUFFIX=$(echo "${URL}" |sed -e 's/?.*//g' | sed -s 's/^.*\.//g')
    local BASE32_URL="$(echo "${URL}" | base32 -w 0)"
    local READY_IMAGE_FILENAME="${VM__READY_IMAGE_CACHE_PATH}/${BASE32_URL}"
    local DECOMPRESSED_IMAGE_FILENAME="${READY_IMAGE_FILENAME}.decompressed"
    # local CHECKSUM_TYPE="$(echo ${DOWNLOAD_LINE} | cut -f 3 -d ' ') | cut -f 1 -d ':'"
    # local CHECKSUM="$(     echo ${DOWNLOAD_LINE} | cut -f 3 -d ' ') | cut -f 1 -d ':'"
    local CHECKSUM_TYPE="$(echo ${DOWNLOAD_LINE} | cut -f 3 -d ' ' | cut -f 1 -d ':')"
    local CHECKSUM="$(     echo ${DOWNLOAD_LINE} | cut -f 3 -d ' ' | cut -f 2 -d ':')"
    local TEMPORARY_IMAGE_FILENAME="${VM__INCOMPLETE_IMAGE_CACHE_PATH}/${BASE32_URL}"

    echo "VM_NAME:                     ${VM_NAME}"
    echo "PREBUILD_VM_NAME:            ${PREBUILD_VM_NAME}"
    echo "DOWNLOAD_LINE:               ${DOWNLOAD_LINE}"
    echo "URL:                         ${URL}"
    echo "FILE_SUFFIX:                 ${FILE_SUFFIX}"
    echo "BASE32_URL:                  ${BASE32_URL}"
    echo "READY_IMAGE_FILENAME:        ${READY_IMAGE_FILENAME}"
    echo "DECOMPRESSED_IMAGE_FILENAME: ${DECOMPRESSED_IMAGE_FILENAME}"
    echo "CHECKSUM_TYPE:               ${CHECKSUM_TYPE}"
    echo "CHECKSUM:                    ${CHECKSUM}"
    echo "TEMPORARY_IMAGE_FILENAME:    ${TEMPORARY_IMAGE_FILENAME}"

    if [ -r "${DECOMPRESSED_IMAGE_FILENAME}" ]; then
        echo "Image already in download cache. Skip download."
    else
        echo
        vm__download_prebuild_to_cache ${URL}
        # echo "Size of downloaded files:"
        # ls -la "${HOME}/.cache/slime-mold/prebuild/ready/"
        local ACTUAL_CHECKSUM="$(vm__file_checksum ${READY_IMAGE_FILENAME} ${CHECKSUM_TYPE})"

        if [ "${ACTUAL_CHECKSUM}" != "${CHECKSUM}" ]; then
            echo "Checksum mismatch."
            echo "Expected:   ${CHECKSUM}"
            echo "Calculated: ${ACTUAL_CHECKSUM}"
            exit 1
        fi

        case "${FILE_SUFFIX}" in
            'qcow2')
                mv "${DECOMPRESSED_IMAGE_FILENAME}" "${DECOMPRESSED_IMAGE_FILENAME}"
                ;;
            'xz')
                echo "Is XZ compressed file. Decompressing QEMU image..."
                cat "${READY_IMAGE_FILENAME}" | xzcat -d > "${DECOMPRESSED_IMAGE_FILENAME}"
                ;;
            *)
                echo "Don't know how to handle file extension: ${FILE_SUFFIX}"
                exit 1
                ;;
        esac
    fi

    cp --reflink=auto "${DECOMPRESSED_IMAGE_FILENAME}" "${VM_NAME}"
}

# Create a new QEMU image of the format
# qcow2. The Image size is 5 gigabyte.
function vm__create_new
{
    IMAGE_NAME="${1}"
    IMAGE_SIZE="5G"

    qemu-img create -f qcow2 "${IMAGE_NAME}" ${IMAGE_SIZE}
}

# Create an overlay image. In an overlay
# image, only the difference to the base
# image is saved. This feature saves a lot
# of memory if you need multible instances
# of the same OS installation.
function vm__create_overlay
{
    local IMAGE_FILE="${1}"
    local BASE_IMAGE_FILE="${2}"

    qemu-img create -b "${BASE_IMAGE_FILE}" -f qcow2 "${IMAGE_FILE}"
}

# Print the status of a virtual machine.
# The status contains the information if
# the VM is running and the corresponding
# log file, which is generated by the
# async_qemu.sh script.
function vm__log
{
    local VM_NAME="${1}"
    local VM_RUNNING
    local VM_LOG_FILE

    VM_RUNNING=$(vm__vm_running "${VM_NAME}")
    if [ "${VM_RUNNING}" = "1" ]; then
        echo "VM running for minutes"
    else
        echo "VM not running."
    fi

    for VM_LOG_FILE in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__*__${VM_NAME}.lock.log"); do
        echo "Logfile exists:"
        cat  "${VM_LOG_FILE}"
    done
}

# Print the status of a virtual machine.
# Known states:
# online)     VM running and ready to take commands
#             over SSH.
# offline)    VM not running.
# booting)    VM running but not yet ready to take
#             commands.
# TODO: Not implemented yet.
# shutdow)    VM received the command to shut down.
# installing) VM is currently installed in an automated
#             manner.
function vm__status
{
    local VM_NAME="${1}"
    local SSH_ERR
    local VM_RUNNING

    vm__vm_running "${VM_NAME}"
    VM_RUNNING=${?}
    if [ "${VM_RUNNING}" = "1" ]; then
        ssh__exec "${VM_NAME}" true 2>/dev/null
        SSH_ERR=${?}
        if [ "${SSH_ERR}" = "0" ]; then
            echo "online"
        else
            echo "booting"
        fi
    else
        echo "offline"
    fi
}

# Print a list of all running VM instances.
function vm__list
{
    local LOCKFILE_NAME
    local VM_NAME
    local VM_SSH_PORT

    for LOCKFILE_NAME in $(find /tmp -maxdepth 1 -name "${PROGRAM_SHORT_NAME}__vde_vm__*__*.lock"); do
        VM_NAME=$(    echo "${LOCKFILE_NAME}" |sed 's|/tmp/${PROGRAM_SHORT_NAME}__vde_vm__||g' |sed 's|.*__||g' |sed 's|.lock||g')
        VM_SSH_PORT=$(echo "${LOCKFILE_NAME}" |sed 's|/tmp/${PROGRAM_SHORT_NAME}__vde_vm__||g' |sed 's|__.*||g' |sed 's|.lock||g')
        echo "${VM_NAME} ${VM_SSH_PORT}"
    done
}

# Print the VM name to a corresponding image
# file.
function vm__image_file_2_vm_name
{
    local VM_NAME

    VM_NAME=$(echo "${IMAGE_FILE}" |sed 's/\ /_/g')
    VM_NAME=$(echo "${IMAGE_FILE}" |sed 's/__/_/g' |sed 's/__/_/g' |sed 's/__/_/g' |sed 's/__/_/g')
    VM_NAME=$(echo $(basename "${VM_NAME}"))
    VM_NAME=${VM_NAME%.*}

    echo "${VM_NAME}"
}
