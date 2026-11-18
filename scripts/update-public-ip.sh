#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
public_ipv4="$(curl -4 -s https://api.ipify.org)/32"
export TF_VAR_my_ipv4_public="$public_ipv4"
echo "$TF_VAR_my_ipv4_public"
echo "Bash value: $TF_VAR_my_ipv4_public"
#terraform plan
