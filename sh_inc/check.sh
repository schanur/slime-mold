# Exits the application if application name does not let us find a
# usable executable.
function check_executable_available
{
    local EXECUTABLE_NAME=${1}
    local EXECUTABLE_FOUND=1

    which ${EXECUTABLE_NAME} > /dev/null || EXECUTABLE_FOUND=0

    if [ ${EXECUTABLE_FOUND} -eq 0 ]; then
        echo "Executable not found: ${EXECUTABLE_NAME}"
        exit 1
    fi
}

# Exits the application if qemu is not available or too old.
function check_qemu
{
    check_executable_available qemu-img
    check_executable_available qemu-system-x86_64
}

# Exits the application if VDE is not available or too old.
function check_vde
{
    check_executable_available vde_switch
}

# Exits the application if SSH is not available or too old.
function check_ssh
{
    check_executable_available scp
    check_executable_available ssh
    check_executable_available ssh-keygen
}

function check_linux_tools
{
    check_executable_available basename
    check_executable_available find
    check_executable_available lockfile
    check_executable_available netstat
    check_executable_available sed
    check_executable_available tar
    check_executable_available unixterm
    check_executable_available xzcat
    check_executable_available whoami
}

# Check if all dependencies are available and equal or newer to the
# minimum requested version. If not, exit the application.
function check_all_dependencies
{
    check_qemu
    check_vde
    check_ssh
    check_linux_tools
}
