function shortcut__list
{
    echo "Switches:"
    switch__list | sed -e 's/^/\ \ \ \ /g'
    echo
    echo "Virtual machines:"
    vm__list     | sed -e 's/^/\ \ \ \ /g'
}
