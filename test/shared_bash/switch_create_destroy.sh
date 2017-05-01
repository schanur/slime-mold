function test__switch_start_checked {
    # local SM_PROGRAM=$1
    local TEST_PATH_PREFIX=$1
    local TEST_SWITCH_NAME=$2
    ${SM_PROGRAM} switch start ${TEST_SWITCH_NAME}
    test   -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}.mgmt || fail "No switch management socket found."
    test   -d ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}      || fail "No switch directory found."
    test   -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}/ctl  || fail "No switch control socket found."
}

function test__switch_stop_checked {
    # local SM_PROGRAM=$1
    local TEST_PATH_PREFIX=$1
    local TEST_SWITCH_NAME=$2
    ${SM_PROGRAM} switch stop  ${TEST_SWITCH_NAME}
    test ! -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}.mgmt || fail "Switch management socket found after switch termination."
    test ! -d ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}      || fail "Switch directory found after switch termination."
    test ! -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}/ctl  || fail "Switch control socket found after switch termination."
}
