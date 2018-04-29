#!/bin/bash

set -o errexit -o nounset -o pipefail
SCRIPT_FILENAME="$(readlink -f "${0}")"
SCRIPT_PATH="$(dirname "${SCRIPT_FILENAME}")"
SM_PATH="${SCRIPT_PATH}/.."


OUT_FILE="${SM_PATH}/sm_full"


if [ -f  "${OUT_FILE}" ]; then
    rm   "${OUT_FILE}"
fi

touch    "${OUT_FILE}"
chmod +x "${OUT_FILE}"


echo "#!/bin/bash" > "${OUT_FILE}"

# for IN_FILE in $(find "vendor/libbivalvia/bivalvia/" *.sh -type f); do
#     cat "${IN_FILE}" | grep -E -v "^source\ .*" >> "${OUT_FILE}"
#     # cat "${IN_FILE}" >> "${OUT_FILE}"
# done

# cat "vendor/libbivalvia/bivalvia/" | grep -E -v "^source\ .*" >> "${OUT_FILE}"

for IN_FILE in $(find "${SM_PATH}/sh_inc/" -name "*.sh" -type f); do
    cat "${IN_FILE}" | grep -E -v "^source\ .*" >> "${OUT_FILE}"
    # cat "${IN_FILE}" >> "${OUT_FILE}"
done

cat "${SM_PATH}/sm" | grep -E -v "^source\ .*" | grep -E -v "^#!/bin/bash$" >> "${OUT_FILE}"
