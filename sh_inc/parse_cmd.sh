function usage
{
    local ADJUSTMENT_VAR__=""

    echo
    echo "${PROGRAM_NAME} usage:"
    echo
    echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
    echo "| ${ADJUSTMENT_VAR__}CMD |  ACTION  |      SUBACTION      | ADDITIONAL PARAMETER |            REQUIRED PARAMETER            |"
    echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
    echo "| ${PROGRAM_SHORT_NAME}    appliance start                                         APPL_FILE                                |"
    echo "| ${PROGRAM_SHORT_NAME}    appliance stop                                          APPL_FILE                                |"
    echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
    echo "| ${PROGRAM_SHORT_NAME}    switch    start                                         SWITCH_NAME                              |"
    echo "| ${PROGRAM_SHORT_NAME}    switch    stop                                          SWITCH_NAME                              |"
#   echo "  ${PROGRAM_SHORT_NAME}    switch    status                                        SWITCH_NAME                              |"
    echo "| ${PROGRAM_SHORT_NAME}    switch    console                                       SWITCH_NAME                              |"
    echo "| ${PROGRAM_SHORT_NAME}    switch    list                                                                                   |"
#   echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
#   echo "  ${PROGRAM_SHORT_NAME}    cable     add                                           SWITCH_NAME_1 SWITCH_NAME_2              |"
#   echo "  ${PROGRAM_SHORT_NAME}    cable     remove                                        SWITCH_NAME_1 SWITCH_NAME_2              |"
    echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
    echo "| ${PROGRAM_SHORT_NAME}    vm        list_prebuild                                                                          |"
    # TODO: Unify name schema. name vs. filename vs vm_image.
    echo "| ${PROGRAM_SHORT_NAME}    vm        create_from_prebuild                          VM_IMAGE      PREBUILD_NAME              |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        create_new                                    VM_IMAGE                                 |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        create_overlay                                VM_IMAGE      VM_BASE_IMAGE              |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        start                                         VM_IMAGE      SWITCH_NAME                |"
#   echo "  ${PROGRAM_SHORT_NAME}    vm        stop                    [-b SEC]              VM_NAME                                  |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        stop                                          VM_NAME                                  |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        kill                                          VM_NAME                                  |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        log                                           VM_NAME                                  |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        status                                        VM_NAME                                  |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        console                                       VM_NAME                                  |"
    echo "| ${PROGRAM_SHORT_NAME}    vm        list                                                                                   |"
    echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
    echo "| ${PROGRAM_SHORT_NAME}    ssh       install_key                                   VM_NAME                                  |"
    echo "| ${PROGRAM_SHORT_NAME}    ssh       send                                          VM_NAME       LOCAL_SOURCE  VM_TARGET    |"
    echo "| ${PROGRAM_SHORT_NAME}    ssh       receive                                       VM_NAME       VM_SOURCE     LOCAL_TARGET |"
    echo "| ${PROGRAM_SHORT_NAME}    ssh       exec                                          VM_NAME       COMMAND                    |"
    echo "| ${PROGRAM_SHORT_NAME}    ssh       login                                         VM_NAME                                  |"
    # echo "| ${PROGRAM_SHORT_NAME}    ssh       exec                    [-l login_name]       VM_NAME       COMMAND                    |"
    # echo "| ${PROGRAM_SHORT_NAME}    ssh       login                   [-l login_name]       VM_NAME                                  |"
    echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
    echo "| ${PROGRAM_SHORT_NAME}    spice     login                                         VM_NAME                                  |"
    echo "--${ADJUSTMENT_VAR__}--------------------------------------------------------------------------------------------------------"
    echo
    echo "Shortcuts:"
    echo
    echo "  ${PROGRAM_SHORT_NAME} list"
    echo
}


function invalid_params
{
    usage
    if [ "${1}" != "" ]; then
        echo "${1}"
    fi
    exit 1
}

# Make some basic checks on the parameters given by the user.
function expected_param
{
    local ARGS=${1}
    local MIN_ARGS=${2}

    # local MAX_ARGS=${3}

    # if [ "${MAX_ARGS}" = "" ]; then
    #     MAX_ARGS=${MIN_ARGS}
    # fi

    # if [ ${ARGS} -lt ${MIN_ARGS} -o ${ARGS} -gt ${MAX_ARGS} ]; then
    if [ ${ARGS} -lt ${MIN_ARGS} ]; then
        invalid_params "Number of parameter not allowed for action \"${ACTION}\" with sub action \"${SUB_ACTION}\""
    fi
}

# Make some basic checks on the parameters given by the user.
function expected_param_num_range
{
    local ARGS=${1}
    local MIN_ARGS=${2}
    local MAX_ARGS=${3}

    if [ ${ARGS} -lt ${MIN_ARGS} ]; then
        invalid_params "Number of parameter not allowed for action \"${ACTION}\" with sub action \"${SUB_ACTION}\""
    fi

    if [ ${ARGS} -gt ${MAX_ARGS} ]; then
        invalid_params "Number of parameter not allowed for action \"${ACTION}\" with sub action \"${SUB_ACTION}\""
    fi
}

function parse_cmd
{
    local ERR=0
    local ACTION
    local SUB_ACTION

    if   [ "$#" = "0" ]; then
        invalid_params "Too few arguments."
    fi

    ACTION=${1}

    if [ "$#" = "1" ]; then
        case "${ACTION}" in
            'list')
                shortcut__list
                ;;
            *)
                invalid_params "Too few arguments."
                ;;
        esac
        exit ${ERR}
    fi

    SUB_ACTION=${2}

    shift 2

    if   [ "${ACTION}" = "appliance" ]; then

        if   [ "${SUB_ACTION}" = "start" ];                then
            expected_param ${#} 1
            appliance__start "${1}"

        elif [ "${SUB_ACTION}" = "stop" ];                 then
            expected_param ${#} 1
            appliance__stop "${1}"

        else
            invalid_params "No valid sub action selected for action \"${ACTION}\"."
        fi
    elif [ "${ACTION}" = "switch" ]; then

        if   [ "${SUB_ACTION}" = "start" ];                then
            expected_param ${#} 1
            switch__start "${1}"

        elif [ "${SUB_ACTION}" = "stop" ];                 then
            expected_param ${#} 1
            switch__stop "${1}"

            # TODO: Remove from API.
        elif [ "${SUB_ACTION}" = "status" ];               then
            expected_param ${#} 1
            switch__status "${1}"

        elif [ "${SUB_ACTION}" = "console" ];              then
            expected_param ${#} 1
            switch__console "${1}"

        elif [ "${SUB_ACTION}" = "list" ];                 then
            expected_param ${#} 0
            switch__list

        else
            invalid_params "No valid sub action selected for action \"${ACTION}\"."
        fi
    elif [ "${ACTION}" = "vm" ];     then

        if   [ "${SUB_ACTION}" = "list_prebuild" ];        then
            expected_param ${#} 0
            vm__list_prebuild

        elif [ "${SUB_ACTION}" = "create_from_prebuild" ]; then
            expected_param ${#} 2
            vm__create_from_prebuild "${1}" "${2}"

        elif [ "${SUB_ACTION}" = "create_new" ];           then
            expected_param ${#} 1
            vm__create_new "${1}"

        elif [ "${SUB_ACTION}" = "create_overlay" ];       then
            expected_param ${#} 2
            vm__create_overlay "${1}" "${2}"

        elif [ "${SUB_ACTION}" = "start" ];                then
            expected_param ${#} 2
            vm__start "${1}" "${2}"

        elif [ "${SUB_ACTION}" = "stop" ];                 then
            expected_param ${#} 1
            vm__stop "${1}"

        elif [ "${SUB_ACTION}" = "kill" ];                 then
            expected_param ${#} 1
            vm__kill "${1}"

        elif [ "${SUB_ACTION}" = "log" ];                  then
            expected_param ${#} 1
            vm__log "${1}"

        elif [ "${SUB_ACTION}" = "status" ];               then
            expected_param ${#} 1
            vm__status "${1}"

        elif [ "${SUB_ACTION}" = "console" ];              then
            expected_param ${#} 1
            vm__console "${1}"

        elif [ "${SUB_ACTION}" = "list" ];                 then
            expected_param ${#} 0
            vm__list

        else
            invalid_params "No valid sub action selected for action \"${ACTION}\"."
        fi
    elif [ "${ACTION}" = "ssh" ];    then

        if   [ "${SUB_ACTION}" = "install_key" ];          then
            expected_param ${#} 1
            ssh__install_key "${1}"

        elif [ "${SUB_ACTION}" = "send" ];                 then
            expected_param ${#} 3
            ssh__send "${1}" "${2}" "${3}"

        elif [ "${SUB_ACTION}" = "receive" ];              then
            expected_param ${#} 3
            ssh__receive "${1}" "${2}" "${3}"

        elif [ "${SUB_ACTION}" = "exec" ];                 then
            #expected_param ${#} 2
            ssh__exec ${*}

        elif [ "${SUB_ACTION}" = "login" ];                then
            expected_param ${#} 1
            ssh__login "${1}"

        else
            invalid_params "No valid sub action selected for action \"${ACTION}\"."
        fi
    elif [ "${ACTION}" = "spice" ];    then

        if   [ "${SUB_ACTION}" = "login" ];                then
            expected_param ${#} 1
            spice__login "${1}"

        else
            invalid_params "No valid sub action selected for action \"${ACTION}\"."
        fi
    else
        invalid_params "\"${ACTION}\" is no valid action."
    fi

}
