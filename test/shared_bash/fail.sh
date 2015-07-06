function close_remaining_sm_resources() {
    local SWITCH

    for SWITCH in $(${SM_PROGRAM} switch list); do
        echo Stopping switch: ${SWITCH}
        ${SM_PROGRAM} switch stop ${SWITCH}
    done


}

function fail() {
    echo -e ${1}
    close_remaining_sm_resources
    exit 1
}

function fail_show_result() {
    echo ${1}
    echo "Result:          ${2}"
    echo "Expected result: ${3}"
    close_remaining_sm_resources
    exit 1
}
