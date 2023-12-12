#!/bin/bash

source "$(dirname $0)/utils.sh"
init
if [ "${REPO}" != "monitors" ]; then
    # Run this script only for monitors repo
    exit 0
fi
echo "Generate symlinks files when does not exist for every monitors modules"
root=$(basename ${PWD})

# loop over every modules
for module in $(browse_modules "$(get_scope ${1:-})" "${REPO}-*.tf"); do
    cd ${module}
    # if common files does not exist
    if ! [ -f common-inputs.tf ]; then
        echo -e "\t- Create common-inputs.tf symlink for module: ${module}"
        if test -f "../../common/module/inputs.tf"; then
            ln -s ../../common/module/inputs.tf common-inputs.tf
        elif test -f "../../../common/module/inputs.tf"; then
            ln -s ../../../common/module/inputs.tf common-inputs.tf
        elif test -f "../../../../common/module/inputs.tf"; then
            ln -s ../../../../common/module/inputs.tf common-inputs.tf
        elif test -f "../../../../../common/module/inputs.tf"; then
            ln -s ../../../../../common/module/inputs.tf common-inputs.tf
        else
            echo "didn't find inputs.tf file"
            exit 1
        fi
    fi
    if ! [ -f common-locals.tf ]; then
        echo -e "\t- Create common-locals.tf symlink for module: ${module}"
        if test -f "../../common/module/locals.tf"; then
            ln -s ../../common/module/locals.tf common-locals.tf
        elif test -f "../../../common/module/locals.tf"; then
            ln -s ../../../common/module/locals.tf common-locals.tf
        elif test -f "../../../../common/module/locals.tf"; then
            ln -s ../../../../common/module/locals.tf common-locals.tf
        elif test -f "../../../../../common/module/locals.tf"; then
            ln -s ../../../../../common/module/locals.tf common-locals.tf
        else
            echo "didn't find locals.tf file"
            exit 1
        fi
    fi
    cd - >> /dev/null
done
