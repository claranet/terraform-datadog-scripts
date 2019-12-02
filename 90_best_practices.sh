#!/bin/bash

source "$(dirname $0)/utils.sh"
init
if [ "${REPO}" != "monitors" ]; then
    # Run this script only for monitors repo
    exit 0
fi
echo "Check best practices respect"

echo -e "\t- Check only one notify_no_data set to true per module"
# loop over every modules
for module in $(browse_modules "$(get_scope ${1:-})" "${REPO}-*.tf"); do
    # check if there is more than 1 notify_no_data not set to false.
    # here the risk to check is the possible "true" value while this could lead the duplicated no data alerts.
    # every metrics from one module come from the same source so this does not make sens to check no data for multiple monitors in the same module.
    if [[ $(cat ${module}/monitors-*.tf | grep 'notify_no_data[[:space:]]*=' | grep -cv '=[[:space:]]*false') -gt 1 ]]; then 
        echo "More than one notify_no_data not set to \"false\" in $module"
        exit 1
    fi
done
