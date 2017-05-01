#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../shared_bash/fail.sh
. ${SCRIPT_DIR}/../shared_bash/switch_create_destroy.sh

SM_PROGRAM="./sm"
SM_LOCKFILE_PATH="/tmp"
SM_LOCKFILE_SWITCH_PREFIX="sm__switch__"

GL_TEST_PATH_PREFIX="${SM_LOCKFILE_PATH}/${SM_LOCKFILE_SWITCH_PREFIX}"
GL_TEST_SWITCH_NAME="test_cases__switch_list"

# Create one switch and check that it is listed correctly.
test__switch_start_checked ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}
SWITCH_LIST="$(${SM_PROGRAM} switch list)"
test "${SWITCH_LIST}" = "${GL_TEST_SWITCH_NAME}" || fail "Created switch is not in list of switches"
test__switch_stop_checked  ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}

# Create two switches and check that they are listed correctly.
EXPECTED_RESULT="${GL_TEST_SWITCH_NAME}_1
${GL_TEST_SWITCH_NAME}_2"
test__switch_start_checked ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}_1
test__switch_start_checked ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}_2
SWITCH_LIST="$(${SM_PROGRAM} switch list)"
test "${SWITCH_LIST}" = "${EXPECTED_RESULT}" || fail_show_result "Created switches are not in list of switches" "${SWITCH_LIST}" "${EXPECTED_RESULT}"
test__switch_stop_checked  ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}_1
test__switch_stop_checked  ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}_2
