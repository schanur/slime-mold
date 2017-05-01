#!/bin/bash

set -o errexit -o nounset -o pipefail
SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/lockfile.sh

IMAGE_FILE=${1}
VM_SSH_PORT=${2}
UMODE_NIC_MAC_ADDR=${3}
VDE_NIC_MAC_ADDR=${4}
VDE_SWITCH_NAME=${5}
LOCKFILE_VM=${6}
HW_ACCELERATION_OPTION=${7}
VM_NAME=${8}
VM_IP=${9}
VM_VLAN=${10}
if [ ${HW_ACCELERATION_OPTION} = "1" ]; then
    HW_ACCELERATION_STR="--enable-kvm"
else
    HW_ACCELERATION_STR=""
fi

#QEMU_CMD="qemu -m 64 ${HW_ACCELERATION_STR} -hda ${IMAGE_FILE}" \
#    " -netdev user,id=um__${VM_NAME},macaddr=${UMODE_NIC_MAC_ADDR},hostfwd=tcp::${VM_SSH_PORT}-:22" \
#    " -netdev vde,macaddr=${VDE_NIC_MAC_ADDR}, sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

#QEMU_CMD="qemu -m 64 ${HW_ACCELERATION_STR} -hda ${IMAGE_FILE} -netdev user,id=um__${VM_NAME},macaddr=${UMODE_NIC_MAC_ADDR},hostfwd=tcp::${VM_SSH_PORT}-:22 -netdev vde,macaddr=${VDE_NIC_MAC_ADDR},sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

#QEMU_CMD="qemu -m 64 ${HW_ACCELERATION_STR} -hda ${IMAGE_FILE} -net user,id=um__${VM_NAME},macaddr=${UMODE_NIC_MAC_ADDR},hostfwd=tcp::${VM_SSH_PORT}-:22 -netdev vde,macaddr=${VDE_NIC_MAC_ADDR},sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

#QEMU_CMD="qemu ${HW_ACCELERATION_STR} -m 64 -hda ${IMAGE_FILE} -net nic,macaddr=${UMODE_NIC_MAC_ADDR} -net user,net=10.0.2.0/24,dhcpstart=${VM_IP},hostfwd=tcp::${VM_SSH_PORT}-:22 -net nic,macaddr=${VDE_NIC_MAC_ADDR} -net vde,sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}"

QEMU_CMD="qemu "                                             \
        "${HW_ACCELERATION_STR} "                            \
        "-m 128 "                                            \
        "-drive file=${IMAGE_FILE},cache=unsafe,discard=on " \
        "-net nic,macaddr=${UMODE_NIC_MAC_ADDR},vlan=${VM_VLAN} -net user,net=10.0.2.0/24,dhcpstart=${VM_IP},hostfwd=tcp::${VM_SSH_PORT}-:22,vlan=${VM_VLAN} " \
        "-net nic,macaddr=${VDE_NIC_MAC_ADDR} -net vde,sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME} "

echo "VM name:      ${VM_NAME}"
echo "Image file:   ${IMAGE_FILE}"
echo "SSH port:     ${VM_SSH_PORT}"
echo "UMN IP:       ${VM_IP}"
echo "UMN VLAN:     ${VM_VLAN}"
echo "UMN MAC addr: ${UMODE_NIC_MAC_ADDR}"
echo "VDE MAC addr: ${VDE_NIC_MAC_ADDR}"
echo "VDE switch:   ${VDE_SWITCH_NAME}"
echo "Lockfile:     ${LOCKFILE_VM}"
echo "Acceleration: ${HW_ACCELERATION_OPTION}"
echo "command:      ${QEMU_CMD}"

lf__create_lockfile ${LOCKFILE_VM}
echo -n "start time: "
date
${QEMU_CMD}
#qemu ${HW_ACCELERATION_STR} -hda ${IMAGE_FILE} -m 64 -net nic,macaddr=${UMODE_NIC_MAC_ADDR},vlan=0 -net user,vlan=0,hostfwd=tcp::${VM_SSH_PORT}-:22 -net nic,macaddr=${VDE_NIC_MAC_ADDR} -net vde,sock=/tmp/${PROGRAM_SHORT_NAME}__switch__${VDE_SWITCH_NAME}
echo -n "stop time:  "
date
lf__destroy_lockfile ${LOCKFILE_VM}
