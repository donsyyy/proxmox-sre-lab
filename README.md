# SRE Observability Stack: Proxmox, Terraform & Ansible

**Goal:** A zero-touch automation pipeline that provisions Debian 12 LXC containers on a bare-metal Proxmox hypervisor using Terraform, and dynamically configures them into a Prometheus observability stack using Ansible.

## Architecture & Tech Stack
* **Hypervisor:** Proxmox VE
* **Infrastructure as Code (IaC):** Terraform (`telmate/proxmox` provider)
* **Configuration Management (CaC):** Ansible
* **Observability:** Prometheus & Node Exporter
* **OS:** Debian 12 (LXC)

### Key Features
* **Zero-Touch Handoff:** Terraform automatically generates the `inventory.ini` file for Ansible using dynamic container IPs.
* **Secure Credential Management:** Utilizes a dedicated `terraform@pve` service account with Privilege Separation properly managed, and secrets isolated in `terraform.tfvars`.
* **Dynamic Configuration:** Ansible uses `blockinfile` and group variables to automatically register target nodes in the Prometheus configuration.

---

## Prerequisites

1. **Proxmox Preparation:**
   * Download the `debian-12-standard` CT template to your Proxmox storage.
   * Create a dedicated `terraform@pve` user in Proxmox and assign it the `Administrator` role.
   * Generate an API Token for this user (**Uncheck** Privilege Separation).

2. **Local Environment:**
   * Install Terraform and Ansible.
   * Generate an SSH Key (`~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`) for passwordless Ansible execution.

---

## Deployment Guide

### Phase 1: Infrastructure Provisioning (Terraform)

1. Clone this repository and navigate to the directory.
2. Create a `terraform.tfvars` file (this file is git-ignored for security) and add your secrets:
   ```hcl
   proxmox_api_secret = "YOUR_SECRET_KEY_HERE"
   ```
3. Update `main.tf` with your Proxmox IP, SSH public key, and desired static IPs.
4. Initialize and apply the infrastructure:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
   *Note: Upon successful completion, Terraform will automatically generate the `inventory.ini` file required for Phase 2.*

