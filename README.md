# AWS Infrastructure Automation with Terraform and Ansible

A hands-on DevOps project that provisions AWS infrastructure with **Terraform**, configures an **Nginx web server with Ansible**, and connects the two using small **Bash automation scripts**.

The goal was to learn the full workflow rather than simply deploy a website: infrastructure as code, reusable modules, remote state, configuration management, secrets handling, idempotency, and troubleshooting.

## Architecture

```text
Linux control node (Terraform + Ansible + Bash)
    |
    | Terraform (AWS API)
    v
AWS eu-north-1
  VPC: 10.0.0.0/16
    └── Public subnet: 10.0.1.0/24
          ├── Internet Gateway + route table (0.0.0.0/0)
          ├── Security Group
          │     ├── SSH 22 from control node's public IPv4 /32
          │     └── HTTP 80 from 0.0.0.0/0
          └── EC2: Amazon Linux 2023 (t3.micro)
                └── Nginx, managed by Ansible

Terraform state: separate S3 backend with native lockfile locking
Terraform output (EC2 public IP) -> Bash-generated Ansible inventory -> SSH -> Nginx
```

**Security note:** SSH access is limited to the current public IPv4 of the control node. HTTP is public for demonstration. The instance, AMI, and region are example lab choices; verify current free-tier eligibility and charges in your own AWS account.

## Technologies

| Tool | Purpose |
| --- | --- |
| Terraform | Provision and manage AWS resources declaratively |
| AWS | VPC, subnet, internet gateway, routes, security group, EC2, S3 |
| Ansible | Install, configure, and verify Nginx |
| Jinja2 | Render a custom HTML landing page |
| Ansible Vault | Practice encrypted variables with a non-production demo secret |
| Bash | Discover the control node's public IP and generate inventory |
| Git / GitHub | Version control and project documentation |

## Project layout

```text
.
├── main.tf                       # Root module and child module wiring
├── variables.tf                  # Root input variables
├── outputs.tf                    # Exposes EC2 public IP
├── backend.tf                    # S3 remote state configuration
├── modules/
│   ├── network/                  # VPC, networking, security group
│   └── compute/                  # EC2 instance and outputs
├── backend-bootstrap/            # Separate Terraform configuration for S3 backend
├── ansible/
│   ├── site.yml                  # Webserver playbook
│   └── roles/
│       └── webserver/
│           ├── tasks/main.yml
│           ├── handlers/main.yml
│           ├── defaults/main.yml
│           ├── templates/index.html.j2
│           ├── files/managed-headers.conf
│           └── vars/secrets.yml # Encrypted demo secret; never commit Vault password
└── scripts/
    ├── generate-inventory.sh     # Terraform public_ip -> Ansible inventory
    └── update-public-ip.sh       # Control-node public IP -> TF_VAR_my_ipv4_public
```

> The tree highlights the important files. It may differ slightly from the local checkout; adapt it to the actual repository before publishing.

## What I implemented and learned

### 1. Terraform modules and AWS networking

- Created reusable **network** and **compute** modules, passing values between them with module inputs and outputs.
- Built a VPC, public subnet, internet gateway, default route, route-table association, and security group.
- Provisioned an Amazon Linux EC2 instance using an SSH key pair.
- Learned why a public subnet needs both a route to an internet gateway and a route-table association, and how root-module variables differ from child-module variables.

### 2. Remote state and locking

- Bootstrapped a separate S3 bucket for Terraform state, with versioning, encryption, and public-access blocking.
- Migrated the main Terraform state from local storage to S3.
- Configured S3 native lockfile locking (`use_lockfile = true`) to reduce concurrent state changes.
- Learned to keep bootstrap infrastructure separate from the resources managed by the main configuration.

### 3. Configuration management with Ansible

- Wrote a `webserver` role to install and start Nginx, enable it at boot, and deploy a custom Jinja2-generated HTML page.
- Added an Nginx configuration file and a handler that reloads Nginx only when notified of a change.
- Checked Nginx configuration with `nginx -t` and tested HTTP headers.
- Reran the playbook to verify **idempotency** (no unnecessary changes on repeat runs).
- Practiced **Ansible Vault** using an encrypted demo password; the password is not required for the static Nginx website.

### 4. Connecting Terraform and Ansible with Bash

- Exposed the EC2 public IP through a Terraform output.
- Built `scripts/generate-inventory.sh` to read `terraform output -raw public_ip` and generate `ansible/inventory.generated.ini` automatically.
- Made the inventory script independent of the terminal's working directory.
- Built `scripts/update-public-ip.sh` to obtain the control node's current public IPv4 and set `TF_VAR_my_ipv4_public` as a `/32` CIDR for the SSH rule.
- Learned that exported variables override Terraform input defaults, but exports from a normally executed Bash script do not persist in its parent shell.

## Prerequisites

- An AWS account with permissions to manage VPC, EC2, security groups, and S3.
- Terraform, AWS CLI, Ansible, Bash, and `curl` installed on the control node.
- AWS credentials configured securely (for example, through an AWS profile or IAM role). **Do not commit credentials.**
- An EC2 SSH key pair available in the selected region; this lab used the key-pair name `test-1` and a private key at `~/.ssh/test-1.pem`.
- Ansible Vault password for the encrypted demo values, if retaining the Vault tasks.

## Deployment workflow

### A. Initialize Terraform

The S3 backend bucket must already exist. If starting from scratch, first provision it with the separate `backend-bootstrap/` configuration and follow its outputs/configuration before initializing the main project.

```bash
terraform init
terraform validate
```

### B. Set the current SSH source IP

The `my_ipv4_public` root input must contain the **public** IPv4 of the machine/network initiating SSH, with `/32` appended. The helper script exports it using the `TF_VAR_` prefix.

If the script only exports this value and is written to be safe to source, run:

```bash
source scripts/update-public-ip.sh
terraform plan
terraform apply
```

If your script runs Terraform internally, execute it normally with `bash` instead. **Check the actual script before sourcing it:** sourcing a script containing `exit` or `cd` affects the interactive shell. Also ensure no `terraform.tfvars`, `*.auto.tfvars`, or `-var` assignment overrides `TF_VAR_my_ipv4_public`.

Review the plan before approving changes. SSH source IP is expected to change when the control node's public IP changes; unrelated resource replacements are not expected from that change alone.

### C. Generate the Ansible inventory

```bash
bash scripts/generate-inventory.sh
ansible-inventory -i ansible/inventory.generated.ini --list
```

The generated inventory is **machine-specific** and intentionally excluded from Git.

### D. Run the Ansible role

```bash
ansible webservers -i ansible/inventory.generated.ini -m ansible.builtin.ping
ansible-playbook -i ansible/inventory.generated.ini ansible/site.yml --ask-vault-pass
```

Run the playbook a second time to check for idempotency. With no infrastructure or configuration changes, the expected recap for the web server is `changed=0`.

### E. Verify the website

```bash
terraform output -raw public_ip
curl -I "http://$(terraform output -raw public_ip)"
```

Check for a successful HTTP response and the custom `X-Managed-By: Ansible` header. Open the public IP in a browser to see the rendered page.

## Security and repository hygiene

- Never commit private keys (`*.pem`, `*.key`), AWS credentials, Vault passwords, Terraform state, or `.terraform/` working directories.
- The encrypted `ansible/roles/webserver/vars/secrets.yml` can be version-controlled if it truly contains only intended encrypted data; the Vault password must remain outside the repository.
- Commit `.terraform.lock.hcl` for reproducible provider selection.
- Keep generated inventory out of Git; it changes with the EC2 public IP.
- Use `git status` and `git diff --cached` to inspect files before every push.

## Lessons learned and possible future improvements

This lab demonstrated the difference between **provisioning** (Terraform) and **configuration management** (Ansible), how to connect tools through outputs and inventory, and how to debug IP addressing, variable precedence, Ansible handlers, and repeatability.

For a production deployment, further work would include safer validation *before* replacing live Nginx configuration, HTTPS/TLS, tighter network exposure, automated testing/CI, and replacing demo secrets with actual application secrets only when needed.

## Cleanup

To avoid unnecessary AWS charges, destroy the **main lab infrastructure** when no longer needed:

```bash
terraform plan -destroy
terraform destroy
```

Keep the S3 remote-state backend available while the main Terraform configuration still uses it. The separate backend bootstrap has its own lifecycle; do not accidentally destroy the state bucket or its contents.

## Project outcome

A working end-to-end example of **Terraform + AWS + Ansible + Bash**: create a server, derive its connection information automatically, configure Nginx, verify the deployment, and manage infrastructure changes through code.
