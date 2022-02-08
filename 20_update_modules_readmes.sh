#!/bin/bash

source "$(dirname $0)/utils.sh"
init
echo "Update README.md for every ${REPO} modules"

# this is the pattern from where custom information is saved to be restored
PATTERN_DOC="Related documentation"

# loop over every modules
for module in $(browse_modules "$(get_scope ${1:-})" "${REPO}-*.tf"); do
    echo -e "\t- Generate README.md for module: ${module}"
    cd ${module}
    EXIST=0
    if [ -f README.md ]; then
        mv README.md README.md.bak
        EXIST=1
    fi
    # module name from path
    module_space=$(list_dirs ${module})
    # module name with space as separator
    module_upper=${module_space^^}
    # module name with dash as separator
    module_dash=${module_space//[ ]/-}
    # module name with slash as separator
    module_slash=${module_space//[ ]/\/}

    # (re)generate README from scratch
    cat <<EOF > README.md
# ${module_upper} DataDog ${REPO}

## How to use this module

\`\`\`hcl
module "datadog-${REPO}-${module_dash}" {
  source      = "claranet/${REPO}/datadog//${module_slash}"
  version     = "{revision}"
EOF

    append=""
    list=""
    last_argument="version"
    if [ "${REPO}" == "monitors" ]; then
        cat <<EOF >> README.md

  environment = var.environment
  message     = module.datadog-message-alerting.alerting-message
EOF
        last_argument="message"
        set +e
        IFS='' read -r -d '' append <<EOF

## Purpose

Creates DataDog monitors with the following checks:
EOF
        set -e
        # gather a information line splitted with "|" for every monitor
        for row in $(terraform-config-inspect --json | jq -c -r '.managed_resources | map([.pos.filename, .pos.line] | join("|")) | join("\n")' | sort -fdbi); do
            # split line for each info one variable
            IFS='|' read filename line < <(echo $row)
            # gather all config HCL code for current monitor
            set +o pipefail
            config=$(tail -n +${line} ${filename} | sed '/^}/q')
            set -o pipefail
            # parse monitor's name
            name=$(get_name "$(echo "${config}" | grep 'name[[:space:]]*=')")
            # search if monitor is enabled
            [[ "$(echo "${config}" | grep 'count[[:space:]]*=')" =~ ^[[:space:]]*count[[:space:]]*=[[:space:]]*var\.([a-z0-9_]*_enabled) ]] &&
            # add "disabled by default" mention if not enabled
            if ! grep -A4 "${BASH_REMATCH[1]}" inputs.tf | grep -q default.*true; then
                name="${name} (disabled by default)"
            fi
            # append new line to list if not empty
            if ! [ -z "${list}" ]; then
                list="${list}\n"
            fi
            # append name to list and improve forecast naming
            list="${list}- ${name/could reach/forecast}"
        done
    fi

    # if README already exist
    if [[ $EXIST -eq 1 ]]; then
        # take all custom config in declaration module example after last argument and until the end of block to restore it
        awk "NR==1,/^[[:space:]]*${last_argument}[[:space:]]*=.*/{flag=1;next}/^}/{flag=0}flag" README.md.bak >> README.md
    fi

    # close block and generate the next until list of modules
    cat <<EOF >> README.md
}

\`\`\`
${append}
EOF

    if ! [ -z "${list}" ]; then
        # write sorted list to readme appending newline to end
        echo -e "$(echo -e "${list}" | sort -fdbi)\n" >> README.md
    fi

    # auto generate terraform docs (inputs and outputs)
    terraform-docs markdown --lockfile=false . >> README.md
    # if README does not exist
    if [[ $EXIST -eq 0 ]]; then
        # Simply add empty documentation section
        cat <<EOF >> README.md
## ${PATTERN_DOC}

EOF
    else
        # else restore the custom information saved before
        grep -Pzo --color=never ".*${PATTERN_DOC}(.*\n)*" README.md.bak | head -n -1 >> README.md
        rm -f README.md.bak
    fi
    # force unix format (I don't know why for now but you never know)
    dos2unix README.md 2> /dev/null
    cd - >> /dev/null
done
