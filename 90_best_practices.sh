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
    # check if there is more than 1 notify_no_data parameter set to true per set of monitors
    if [[ $(cat ${module}/monitors-*.tf | grep -c notify_no_data.*var\.*) -gt 1 ]]; then 
        echo "More than one notify_no_data set with variable on $module"
        exit 1
    fi
done
