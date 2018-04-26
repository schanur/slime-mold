###!/usr/bin/env bash

function _sm()
{
    COMPREPLY=()

    local CURR="${COMP_WORDS[COMP_CWORD]}"
    local ACTION=""
    local SUBACTION=""
    local COMBINED_ACTION=""
    local COMPLETION_FOUND=1

    local ACTIVE_SWITCH_LIST=""
    local ACTIVE_VM_LIST=""

    local SUBACTION_PARAM_CNT
    local SUBACTION_PARAM_1=""
    local SUBACTION_PARAM_2=""
    local SUBACTION_PARAM_3=""

    local ADDITIONAL_PARAMS_ALLOWED=1
    local I

    local SM_CMD="sm"

    local COMPLETE_ACTION="none"

    which "${SM_CMD}" > /dev/null || SM_CMD="echo \"\""
    # which "${SM_CMD}" || SM_CMD="echo \"slime mold command 'sm' not found. No completion available\""


    local ACTIONS_OPTS="\
appliance \
switch \
vm \
ssh \
spice \
list"
    local APPLIANCE_SUBACTION_OPTS="\
start \
stop"
    local SWITCH_SUBACTION_OPTS="\
start \
stop \
console \
list"
    local VM_SUBACTION_OPTS="\
list_prebuild \
create_from_brebuild \
create_new \
create_overlay \
start \
stop \
kill \
log \
status \
list"
    local SSH_SUBACTION_OPTS="\
install_key \
send \
receive \
exec \
login"
    local SPICE_SUBACTION_OPTS="\
login"
#     OPTS="\
# --help \
# --verbose \
# --version"

    case ${COMP_CWORD} in
    1)
        ACTION="${COMP_WORDS[1]}"
        ;;
    *)
        ACTION="${COMP_WORDS[1]}"
        SUBACTION="${COMP_WORDS[2]}"
        COMBINED_ACTION="${ACTION}_${SUBACTION}"
        ;;
    esac

    case ${COMP_CWORD} in
        1)
            COMPREPLY=( $(compgen -W "${ACTIONS_OPTS}" -- "${CURR}") )
            ;;

        2)
            case "${ACTION}" in
                appliance) COMPREPLY=( $(compgen -W "${APPLIANCE_SUBACTION_OPTS}" -- "${CURR}") ) ;;
                switch)    COMPREPLY=( $(compgen -W "${SWITCH_SUBACTION_OPTS}"    -- "${CURR}") ) ;;
                vm)        COMPREPLY=( $(compgen -W "${VM_SUBACTION_OPTS}"        -- "${CURR}") ) ;;
                ssh)       COMPREPLY=( $(compgen -W "${SSH_SUBACTION_OPTS}"       -- "${CURR}") ) ;;
                spice)     COMPREPLY=( $(compgen -W "${SPICE_SUBACTION_OPTS}"     -- "${CURR}") ) ;;
                *)
                    COMPLETION_FOUND=0
                    ;;
            esac
            ;;

        3notimplemented)
            # SUBACTION_PARAM_CNT=${COMP_CWORD}
            # I=0
            # while [ ${I} -le ${COMP_CWORD} ]; do
            #     ${COMP_WORDS[COMP_CWORD]
            #     if [  ]
            #        ADDITIONAL_PARAMS_ALLOWED
            #     (( I = I + 1 ))
            # done

            # TODO: Implement
            # if [[ ${CURR} == -* ]] ; then
            #     COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            #     return 0
            # fi
            true
            ;;

        3)
            case "${COMBINED_ACTION}" in
                appliance_start)         COMPLETE_ACTION="appliance_file" ;;
                appliance_stop)          COMPLETE_ACTION="appliance_file" ;;

                switch_start)            COMPLETE_ACTION="new_switch" ;;
                switch_stop)             COMPLETE_ACTION="active_switch" ;;
                switch_console)          COMPLETE_ACTION="active_switch" ;;
                switch_list)             COMPLETE_ACTION="none" ;;

                vm_list_prebuild)        COMPLETE_ACTION="none" ;;
                vm_create_from_prebuild) COMPLETE_ACTION="new_vm_file" ;;
                vm_create_new)           COMPLETE_ACTION="not_implemented" ;;
                vm_create_overlay)       COMPLETE_ACTION="new_vm_file" ;;
                vm_start)                COMPLETE_ACTION="inactive_vm_file" ;;
                vm_stop)                 COMPLETE_ACTION="active_vm" ;;
                vm_kill)                 COMPLETE_ACTION="active_vm" ;;
                vm_log)                  COMPLETE_ACTION="active_vm" ;;
                vm_status)               COMPLETE_ACTION="active_vm" ;;
                vm_list)                 COMPLETE_ACTION="none" ;;

                ssh_install_key)         COMPLETE_ACTION="active_vm" ;;
                ssh_send)                COMPLETE_ACTION="active_vm" ;;
                ssh_receive)             COMPLETE_ACTION="active_vm" ;;
                ssh_exec)                COMPLETE_ACTION="active_vm" ;;
                ssh_login)               COMPLETE_ACTION="active_vm" ;;

                spice_login)             COMPLETE_ACTION="active_vm" ;;
            esac
            ;;

        4)
            case "${COMBINED_ACTION}" in
                vm_create_from_prebuild) COMPLETE_ACTION="vm_name_from_repo" ;;
                vm_create_overlay)       COMPLETE_ACTION="inactive_vm_file" ;;
                vm_start)                COMPLETE_ACTION="active_switch" ;;

                ssh_send)                COMPLETE_ACTION="local_file" ;;
                ssh_receive)             COMPLETE_ACTION="remote_file" ;;
                ssh_exec)                COMPLETE_ACTION="remote_command" ;;
            esac
            ;;

        5)
            case "${COMBINED_ACTION}" in
                ssh_send)                COMPLETE_ACTION="remote_file" ;;
                ssh_receive)             COMPLETE_ACTION="local_file" ;;
            esac
            ;;

        *)
            true
            ;;
    esac
    # echo ${CURR}
    # echo

    case "${COMPLETE_ACTION}" in
        appliance_file)    COMPREPLY=( $(compgen -f -- "${CURR}") ) ;;

        new_switch)        true ;;
        active_switch)     COMPREPLY=( $(compgen -W "$("${SM_CMD}" switch list | tr '\n' ' ')" -- "${CURR}") ) ;;
        # active_switch)     COMPREPLY=( $(compgen -W "a b c" -- "${CURR}") ) ;;

        vm_file)           COMPREPLY=( $(compgen -f -- "${CURR}") ) ;;
        new_vm_file)       true ;;
        active_vm)         COMPREPLY=( $(compgen -W "$("${SM_CMD}" vm     list | tr '\n' ' ')" -- "${CURR}") ) ;;
        vm_name_from_repo) COMPREPLY=( $(compgen -W "$("${SM_CMD}" vm     list | tr '\n' ' ')" -- "${CURR}") ) ;;
        inactive_vm_file)  COMPREPLY=( $(compgen -f -- "${CURR}") ) ;; # TODO: Filter active VMs. Problem is instance name <-> filename conversion.

        local_file)        COMPREPLY=( $(compgen -f -- "${CURR}") ) ;;
        remote_file)       true ;;
        remote_command)    true ;;

        none)              true ;;
        not_implemented)   true ;;
    esac


    # echo  "---"
    # echo ${COMPREPLY}
    # echo  "---"

    # if [[ ${cur} == -* ]] ; then
    #     COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    #     return 0
    # fi

    if [ ${COMPLETION_FOUND} -eq 1 ]; then
        return 0
    else
        return 1
    fi
}


complete -F _sm sm
