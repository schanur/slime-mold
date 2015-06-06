# Globals
#VM__RUNNING_VM_LIST=""
VM__FOUND_PID=""
VM__FOUND_FREE_PORT=""
VM__FOUND_FREE_IP=""
VM__FOUND_FREE_VLAN=""
VM__UNIQUE_MAC_ADDR=""
VM__USED_IP_BYTE_LIST=""
VM__USED_VLAN_LIST=""
# Check if OS has hardware virtualization
# support. If OS supports KVM, return 1.
# Return 0 otherwise.
function vm__check_kvm_extension() {
    local CPU_FLAGS_FOUND
    local HW_ACCELERATION=0

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
                HW_ACCELERATION=1
            fi
        fi
    fi

    if [ "${HW_ACCELERATION}" = "0" ]; then
        echo "No usable configuration for hardware acceleration found. Software emulation is used instead."
    fi

    return ${HW_ACCELERATION}
}

# Find a free TCP port in the range of 12201 - 12299 on the host.
function vm__find_free_tcp_port()
{
    local PORT
    local PORT_FREE
    local PORT_IN_USE
    local USED_PORT
    local FREE_PORT_FOUND
    local FOUND_IN_LOCKFILE

    FREE_PORT_FOUND=0

    # Get a list of all listening ports from the OS.
    PORTS_IN_USE=$(netstat -nl --protocol=inet |grep LISTEN |sed 's/ \+\ /\ /g' |cut -d " " -f 4 |sed 's/.*://g' |grep "122")

    for PORT in $(seq 12201 12299); do
        # Skip testing ports that are marked as already listening.
        PORT_IN_USE=0
        for USED_PORT in ${PORTS_IN_USE}; do
            if [ "${PORT}" = "${USED_PORT}" ]; then
                PORT_IN_USE=1
                break
            fi
        done
        if [ "${PORT_IN_USE}" = "1" ]; then
            continue
        fi
        # We found a free port by looking into the netstat table.
        # We also check that the port doesn't occur in the lockfiles.
        FOUND_IN_LOCKFILE=$(find /tmp -maxdepth 1 -name "virtnet__vde_vm__${PORT}__*.lock" |wc -l)
        if [ "${FOUND_IN_LOCKFILE}" != "0" ]; then
            echo "Warning! TCP port ${PORT} is not listening, but lockfile exists."
            continue
        fi
        VM__FOUND_FREE_PORT=${PORT}
        return
    done
    echo "All TCP ports in the range 12201-12299 are in use"
    exit 1
}

# Generate a list of IPs used by the QEMU slirp
# network backend.
function vm__used_ip_list()
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
function vm__find_free_ip()
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
function vm__used_vlan_list()
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
function vm__find_free_vlan()
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


# Generate a unique MAC address based
# on the VM name, where the same VM name
# will always generate the same MAC
# address.
# 
function vm__unique_mac()
{
    local VM_NAME=$1
    local SALT=$2
    local PREFIX="00:80:AD"
    local HASH

    HASH=$(echo ${VM_NAME}${SALT} |sha512sum)
    
    VM__UNIQUE_MAC_ADDR="${PREFIX}:${HASH:0:2}:${HASH:2:2}:${HASH:4:2}"
}

# Start a VM in a non blocking way.
function vm__start()
{
    local IMAGE_FILE=$1
    local VDE_SWITCH_NAME=$2
    local VDE_NIC_MAC_ADDR
    local UMODE_NIC_MAC_ADDR
    local VM_NAME
    local VM_RUNNING
    local VM_SSH_PORT
    local VM_IP
    local VM_VLAN
    local LOCKFILE_VM
    local HW_ACCELERATION


    VM_NAME=$(vm__image_file_2_vm_name ${IMAGE_FILE})

    vm__vm_running ${VM_NAME}
    VM_RUNNING=${?}
    if [ "${VM_RUNNING}" = "1" ]; then
        echo "VM is already running"
        exit 1
    fi

    vm__unique_mac ${VM_NAME} "umode"
    UMODE_NIC_MAC_ADDR=${VM__UNIQUE_MAC_ADDR}

    vm__unique_mac ${VM_NAME} "vde"
    VDE_NIC_MAC_ADDR=${VM__UNIQUE_MAC_ADDR}

    vm__find_free_tcp_port
    VM_SSH_PORT=${VM__FOUND_FREE_PORT}

    vm__find_free_ip
    VM_IP=${VM__FOUND_FREE_IP}

    vm__find_free_vlan
    VM_VLAN=${VM__FOUND_FREE_VLAN}
    echo ${VM_VLAN}

    lf__lockfile_name ${VM_SSH_PORT} ${VM_NAME}
    LOCKFILE_VM=${LF__LOCKFILE_NAME}

    vm__check_kvm_extension
    HW_ACCELERATION=${?}

    nohup bash sh_inc/async_qemu.sh ${IMAGE_FILE} ${VM_SSH_PORT} ${UMODE_NIC_MAC_ADDR} ${VDE_NIC_MAC_ADDR} ${VDE_SWITCH_NAME} ${LOCKFILE_VM} ${HW_ACCELERATION} ${VM_NAME} ${VM_IP} ${VM_VLAN} > ${LOCKFILE_VM}.log 2>&1&
}

# Stop the VM by sending the "halt" command
# over SSH. 
function vm__stop()
{
    local VM_NAME=${1}

    ssh__exec ${VM_NAME} halt
}

# Stop the VM by sending the "halt" command
# over SSH. The function blocks until the VM
# has shut down.
# TODO: It still blocks.
function vm__stop_blocking()
{
    local VM_NAME=${1}

    vm__stop ${VM_NAME}
}



# Check if the VM name occurs in a lockfile.
# Return values:
# 1 if VM is running.
# 0 if VM is not running.
function vm__vm_running()
{
    local LOCKFILE_NAME_PARTIAL
    local MATCH_CNT
    local VM_NAME=${1}

    MATCH_CNT=0
    for LOCKFILE_NAME_PARTIAL in $(find /tmp -maxdepth 1 -name "virtnet__vde_vm__*__${VM_NAME}.lock"); do
        (( MATCH_CNT++ ))
    done

    if   [[ "${MATCH_CNT}" = "1" ]]; then
        return 1
    elif [[ "${MATCH_CNT}" = "0" ]]; then
        return 0
    else
        echo "Error: More than one lockfile found for \"virtnet__vde_vm__*__${VM_NAME}.lock\""
        exit 1
    fi
}

# Create a new QEMU image of the format
# qcow2. The Image size is 5 gigabyte.
function vm__create_new()
{
    IMAGE_NAME=${1}
    IMAGE_SIZE="5G"

    qemu-img create -f qcow2 ${IMAGE_NAME} ${IMAGE_SIZE}
}

# Create an overlay image. In an overlay
# image, only the difference to the base
# image is saved. This feature saves a lot
# of memory if you need multible instances
# of the same OS installation.
function vm__create_overlay()
{
    local IMAGE_FILE=${1}
    local BASE_IMAGE_FILE=${2}

    qemu-img create -b ${BASE_IMAGE_FILE} -f qcow2 ${IMAGE_FILE}
}

# Print the status of a virtual maschine.
# The status contains the information if
# the VM is running and the corresponding
# log file, which is generated by the
# async_qemu.sh script.
function vm__log()
{
    local VM_NAME=$1
    local VM_RUNNING
    local VM_LOG_FILE

    vm__vm_running ${VM_NAME}
    VM_RUNNING=${?}
    if [ "${VM_RUNNING}" = "1" ]; then
        echo "VM running for minutes"
    else
        echo "VM not running."
    fi

    for VM_LOG_FILE in $(find /tmp -maxdepth 1 -name "virtnet__vde_vm__*__${VM_NAME}.lock.log"); do
        echo "Logfile exists:"
        cat  ${VM_LOG_FILE}
    done
}

# Print the status of a virtual maschine.
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
function vm__status()
{
    local VM_NAME=$1
    local SSH_ERR
    local VM_RUNNING

    vm__vm_running ${VM_NAME}
    VM_RUNNING=${?}
    if [ "${VM_RUNNING}" = "1" ]; then
        ssh__exec ${VM_NAME} true 2>/dev/null
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
function vm__list()
{
    local LOCKFILE_NAME
    local VM_NAME
    local VM_SSH_PORT

    for LOCKFILE_NAME in $(find /tmp -maxdepth 1 -name "virtnet__vde_vm__*__*.lock"); do
        VM_NAME=$(    echo ${LOCKFILE_NAME} |sed 's|/tmp/virtnet__vde_vm__||g' |sed 's|.*__||g' |sed 's|.lock||g')
        VM_SSH_PORT=$(echo ${LOCKFILE_NAME} |sed 's|/tmp/virtnet__vde_vm__||g' |sed 's|__.*||g' |sed 's|.lock||g')
        echo ${VM_NAME} ${VM_SSH_PORT}
    done
}

# Print the VM name to a corresponding image
# file.
function vm__image_file_2_vm_name()
{
    local VM_NAME

    VM_NAME=$(echo ${IMAGE_FILE} |sed 's/\ /_/g')
    VM_NAME=$(echo ${IMAGE_FILE} |sed 's/__/_/g' |sed 's/__/_/g' |sed 's/__/_/g' |sed 's/__/_/g')
    VM_NAME=$(echo $(basename ${VM_NAME}))
    VM_NAME=${VM_NAME%.*}

    echo ${VM_NAME}
}