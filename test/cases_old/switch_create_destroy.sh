#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPT_DIR=$(dirname $0)
. ${SCRIPT_DIR}/../shared_bash/fail.sh
. ${SCRIPT_DIR}/../shared_bash/switch_create_destroy.sh

SM_PROGRAM="./sm"
SM_LOCKFILE_PATH="/tmp"
SM_LOCKFILE_SWITCH_PREFIX="sm__switch__"

GL_TEST_SWITCH_NAME="test_cases__switch_1"
GL_TEST_PATH_PREFIX="${SM_LOCKFILE_PATH}/${SM_LOCKFILE_SWITCH_PREFIX}"

test__switch_start_checked ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}
test__switch_stop_checked  ${GL_TEST_PATH_PREFIX} ${GL_TEST_SWITCH_NAME}
