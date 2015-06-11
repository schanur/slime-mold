#!/bin/bash

function fail() {
    echo ${1}
    exit 1
}

SM_PROGRAM="./sm"
SM_LOCKFILE_PATH="/tmp"
SM_LOCKFILE_SWITCH_PREFIX="sm__switch__"

TEST_SWITCH_NAME="test_cases__switch_1"
TEST_PATH_PREFIX="${SM_LOCKFILE_PATH}/${SM_LOCKFILE_SWITCH_PREFIX}"



${SM_PROGRAM} switch start ${TEST_SWITCH_NAME}

test   -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}.mgmt || fail "No switch management socket found."
test   -d ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}      || fail "No switch directory found."
test   -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}/ctl  || fail "No switch control socket found."

${SM_PROGRAM} switch stop  ${TEST_SWITCH_NAME}

test ! -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}.mgmt || fail "Switch management socket found after switch termination."
test ! -d ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}      || fail "Switch directory found after switch termination."
test ! -S ${TEST_PATH_PREFIX}${TEST_SWITCH_NAME}/ctl  || fail "Switch control socket found after switch termination."
