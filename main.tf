terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://192.168.1.98:8006/api2/json"
  pm_api_token_id     = "terraform@pve!tf-token"
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

# ----------------------------------------------------
# Node 1: The Prometheus SRE Server
# ----------------------------------------------------
resource "proxmox_lxc" "prometheus_server" {
  target_node  = "pve" 
  hostname     = "prometheus-server"
  ostemplate   = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  unprivileged = true
  start        = true

  # This locks the root user from password logins and injects your SSH key
  ssh_public_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXP/cSypm7iQMxAbkwMNldAXKprKriJwWe4YbgZ0Zb7 proxmox-lab"

  cores  = 1
  memory = 1024
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.1.50/24"
    gw     = "192.168.1.1" 
  }
}

# ----------------------------------------------------
# Node 2: The Target Node to monitor
# ----------------------------------------------------
resource "proxmox_lxc" "target_node" {
  target_node  = "pve"
  hostname     = "target-node"
  ostemplate   = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  unprivileged = true
  start        = true

  ssh_public_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXP/cSypm7iQMxAbkwMNldAXKprKriJwWe4YbgZ0Zb7 proxmox-lab"

  cores  = 1
  memory = 512
  rootfs {
    storage = "local-lvm"
    size    = "4G"
  }
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.1.60/24"
    gw     = "192.168.1.1"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<-EOF
    [prometheus]
    ${split("/", proxmox_lxc.prometheus_server.network[0].ip)[0]} ansible_user=root

    [targets]
    ${split("/", proxmox_lxc.target_node.network[0].ip)[0]} ansible_user=root
  EOF
}