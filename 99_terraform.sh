#!/bin/bash

source "$(dirname $0)/utils.sh"
init
echo "Check terraform CI"

# Clean when exit
err() {
    rm -f "${module}/tmp.tf"
}
trap 'err $LINENO' ERR TERM EXIT INT

provider_version=$(grep -m1 ^[[:space:]]*version[[:space:]]= README.md | awk '{print $3}')

# loop over every modules
for module in $(browse_modules "$(get_scope ${1:-})" 'inputs.tf'); do
    echo -e "\t- Terraform validate on module: ${module}"
    cat <<EOF > ${module}/tmp.tf
provider "datadog" {
  version = $provider_version

  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
}

variable "datadog_api_key" {
  type = string
  default = "xxx"
}

variable "datadog_app_key" {
  type = string
  default = "yyy"
}

EOF

    if grep -q required_providers ${module}/versions.tf ; then
        if ! grep -q '"terraform-providers/datadog"' ${module}/versions.tf ; then
            cp -a ${module}/versions.tf{,.bak}
            sed -i '/required_providers/a     datadog = {\n      source = "terraform-providers/datadog"\n    }' ${module}/versions.tf
        fi
    else
        cat <<EOF > ${module}/tmp.tf
terraform {
  required_providers {
    datadog = {
      source = "terraform-providers/datadog"
    }
  }
}
EOF
    fi

    if [ -f ${module}/test.tf.ci ]; then
        cat ${module}/test.tf.ci >> ${module}/tmp.tf
    fi
    terraform init ${module} > /tmp/null
    terraform validate ${module}
    rm -f ${module}/tmp.tf
    if [ -f ${module}/versions.tf.bak ]; then
        mv -f ${module}/versions.tf{.bak,}
    fi
done

echo -e "\t- Terraform fmt recursive"
terraform fmt -recursive

