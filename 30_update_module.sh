#!/bin/bash

source "$(dirname $0)/utils.sh"
init
if [ "${REPO}" != "monitors" ]; then
    # Run this script only for monitors repo
    exit 0
fi
echo "Generate outputs.tf files when does not exist for every monitors modules"
root=$(basename ${PWD})

# loop over every modules
for module in $(browse_modules "$(get_scope ${1:-})" "${REPO}-*.tf"); do
    cd ${module}
    # get name of the monitors set directory
    resource="$(basename ${module})"
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
    # if modules.tf does not exist AND if this set respect our tagging convention
    if ! [ -f modules.tf ] && grep -q filter_tags_use_defaults inputs.tf; then
        echo -e "\t- Generate modules.tf for module: ${module}"
        relative=""
        current="${PWD}"
        # iterate on path until we go back to root
        while [[ "$(basename $current)" != "$root" ]]; do
            # for each iteration add "../" to generate relative path
            relative="${relative}../"
            # remove last directory from current path
            current="$(dirname $current)"
        done
        # add the filter tags module
        cat > modules.tf <<EOF
module "filter-tags" {
  source = "${relative}common/filter-tags"

  environment                 = var.environment
  resource                    = "$resource"
  filter_tags_use_defaults    = var.filter_tags_use_defaults
  filter_tags_custom          = var.filter_tags_custom
  filter_tags_custom_excluded = var.filter_tags_custom_excluded
}

EOF
    fi
    cd - >> /dev/null
done
