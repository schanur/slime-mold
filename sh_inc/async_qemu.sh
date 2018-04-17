#!/bin/bash

set -o errexit -o nounset
# set -o errexit -o nounset -o pipefail
SCRIPT_PATH=$(dirname $0)

source ${SCRIPT_PATH}/lock.sh


PROGRAM_SHORT_NAME=${1}
IMAGE_FILE=${2}
VM_SSH_PORT=${3}
VM_SPICE_PORT=${4}
UMODE_NIC_MAC_ADDR=${5}
VDE_NIC_MAC_ADDR=${6}
VDE_SWITCH_NAME=${7}
LOCKFILE_VM=${8}
HW_ACCELERATION_OPTION=${9}
VM_NAME=${10}
VM_IP=${11}
VM_VLAN=${12}
VM_MEM="256"

HW_ACCELERATION_STR=""


if [ ${HW_ACCELERATION_OPTION} = "1" ]; then
    HW_ACCELERATION_STR="--enable-kvm"
fi

#QEMU_CMD="qemu -m 64 ${HW_ACCELERATION_STR} -hda ${IMAGE_FILE}" \
#    " -netdev user,id=um__${VM_NAME},macaddr=${UMODE_NIC_MAC_ADDR},hostfwd=tcp::${VM_SSH_PORT}-:22" \
#    " -netdev vde,macaddr=${VDE_NIC_MAC_ADDR}, sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

#QEMU_CMD="qemu -m 64 ${HW_ACCELERATION_STR} -hda ${IMAGE_FILE} -netdev user,id=um__${VM_NAME},macaddr=${UMODE_NIC_MAC_ADDR},hostfwd=tcp::${VM_SSH_PORT}-:22 -netdev vde,macaddr=${VDE_NIC_MAC_ADDR},sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

#QEMU_CMD="qemu -m 64 ${HW_ACCELERATION_STR} -hda ${IMAGE_FILE} -net user,id=um__${VM_NAME},macaddr=${UMODE_NIC_MAC_ADDR},hostfwd=tcp::${VM_SSH_PORT}-:22 -netdev vde,macaddr=${VDE_NIC_MAC_ADDR},sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

#QEMU_CMD="qemu ${HW_ACCELERATION_STR} -m 64 -hda ${IMAGE_FILE} -net nic,macaddr=${UMODE_NIC_MAC_ADDR} -net user,net=10.0.2.0/24,dhcpstart=${VM_IP},hostfwd=tcp::${VM_SSH_PORT}-:22 -net nic,macaddr=${VDE_NIC_MAC_ADDR} -net vde,sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

#-vga none \

INTERACTIVE_QEMU_CMD="\
qemu-system-x86_64 \
${HW_ACCELERATION_STR} \
-m ${VM_MEM} \
-drive file=${IMAGE_FILE},cache=unsafe,discard=on \
-net nic,macaddr=${UMODE_NIC_MAC_ADDR},vlan=${VM_VLAN} -net user,net=10.0.2.0/24,dhcpstart=${VM_IP},hostfwd=tcp::${VM_SSH_PORT}-:22,vlan=${VM_VLAN} \
-net nic,macaddr=${VDE_NIC_MAC_ADDR} -net vde,sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

BACKGROUND_QEMU_CMD="\
${INTERACTIVE_QEMU_CMD} \
-display none \
-spice port=${VM_SPICE_PORT},disable-ticketing \
"

# QEMU_CMD=${INTERACTIVE_QEMU_CMD}
QEMU_CMD=${BACKGROUND_QEMU_CMD}

echo "Program short name:    ${PROGRAM_SHORT_NAME}"
echo "VM name:               ${VM_NAME}"
echo "Image file:            ${IMAGE_FILE}"
echo "SSH port:              ${VM_SSH_PORT}"
echo "Spice port:            ${VM_SPICE_PORT}"
echo "UMN IP:                ${VM_IP}"
echo "UMN VLAN:              ${VM_VLAN}"
echo "UMN MAC addr:          ${UMODE_NIC_MAC_ADDR}"
echo "VDE MAC addr:          ${VDE_NIC_MAC_ADDR}"
echo "VDE switch:            ${VDE_SWITCH_NAME}"
echo "Lockfile:              ${LOCKFILE_VM}"
echo "Acceleration:          ${HW_ACCELERATION_OPTION}"
echo "Hardware Acceleration: ${HW_ACCELERATION_OPTION}"
echo
echo "Command:"
echo "${QEMU_CMD}"


lf__create_lockfile ${LOCKFILE_VM}

echo "qemu parent PID: ${$}"
echo "Start time:      $(date)"
RET=0
echo "Start processs in background."
${QEMU_CMD} || RET=${?}
echo "Return code:     ${RET}"
echo "Stop time:       $(date)"

lf__destroy_lockfile ${LOCKFILE_VM}
