#!/bin/bash

TEST_CASES_PATH="test/cases"

function run_test() {
    local TEST_PATH=$1
    local TEST_SCRIPT_NAME=$2
    local TEST_SCRIPT_ABS_FILENAME=${TEST_PATH}/${TEST_SCRIPT_NAME}
    local TEST_RETURN_CODE

    echo -n "Test case: ${TEST_SCRIPT_ABS_FILENAME} "
    ./${TEST_SCRIPT_ABS_FILENAME}
    TEST_RETURN_CODE=$?
    if [ "${TEST_RETURN_CODE}" = "0" ]; then
        echo "ok"
    else
        echo "failed"
    fi
}

function run_all_tests_in_directory() {
    local TEST_PATH=$1
    for TEST_SCRIPT in $(ls ${TEST_PATH}); do
        run_test ${TEST_PATH} ${TEST_SCRIPT}
    done
}

run_all_tests_in_directory ${TEST_CASES_PATH}
