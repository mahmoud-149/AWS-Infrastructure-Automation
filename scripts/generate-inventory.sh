#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
if ! public_ip=$(terraform output -raw public_ip); then
    echo "Command failed" >&2
    exit 1
fi   

if [[ -z "$public_ip" ]]; then
    echo "there is no public ip"
    exit 1
fi 
cat > ansible/inventory.generated.ini <<EOF
[webservers]
aws_host   ansible_user=ec2-user ansible_host=$public_ip  ansible_ssh_private_key_file=~/.ssh/test-1.pem
EOF
