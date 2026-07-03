###############################################################################
# main.tf — Clúster Galera MariaDB (3 nodos) en QEMU/KVM
# Provider: dmacvicar/libvirt = 0.7.6
# Ubuntu 22.04 LTS (Jammy) — imagen local en ~/vmstore/images
###############################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "= 0.7.6"
    }
  }
}

###############################################################################
# Variables
###############################################################################

variable "vm_count" {
  description = "Número de nodos del clúster Galera"
  type        = number
  default     = 3
}

variable "vm_memory_mb" {
  description = "RAM por VM en MiB"
  type        = number
  default     = 2048
}

variable "vm_vcpu" {
  description = "vCPUs por VM"
  type        = number
  default     = 2
}

variable "disk_size_bytes" {
  description = "Tamaño de disco por VM en bytes (20 GiB)"
  type        = number
  default     = 21474836480
}

variable "base_ip" {
  description = "Primeros tres octetos de la red"
  type        = string
  default     = "192.168.100"
}

variable "host_user" {
  description = "Usuario del host (para construir rutas absolutas)"
  type        = string
  default     = "coto"
}

variable "ssh_public_key" {
  description = "Llave pública SSH para las VMs"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJIf20qcPbFD19Oe7FBc2hpClV9cytwGOJAo98EYTRks45Pjxz5BRJEhNl5984NYQh/LLvIflvWsURvGMjbylnvAFWDgE7V58rE5S+oVi5GjD0L/EwrTksFFkUBloLgNkKJDMOcGpr3jc7KpKy9kseMjdb+4HxcioSCycgd2GzEloNKyLuQG4VWW2FAwcKl03ODHj0ylpscx5kqeGhjzUAWBB+LgK83GQzUj2bWP5BzepWPjhBCNFWKwkcCOPOV/DztmL2MNSx7zPAYSWN2Co6wfdn8vQUjrMAV7AgNQAjh+EMhd8Q0xxHlhaujT0RGCpmPPGECKxTdcH+C2XaQZyuUCs3O0Zmlp1ASrSBkfQh1ruUKmgyls2z4wO/QILF3X8xRyXbCZbXTpwD71jiXw1I/t7JFMaQS/Q15CnweIZE9NH296Ng7tAMkQUATqxO8Fd/7OMf8QJmQK7NhId3hQKcXIkSaexJUvxX+lO5tGJ0nooo7QR7+sA2rGyhnMhOzib3gwLIkH6fOvrLA3Icpg/lJqhFBzy7hC5uj2GIZGY7+MADYfGk1EYngjTUvvVnedZcFuFtMnWA6Z1fEsm8GtjngjpLIF70AK0FyzfKEthv1jevTqxPzlqmBNCPziuzp66IH2Ytard41p5fwXIzZkdAKl4KcFLzUHtz7VlLq3noAw== jdelpino2020@alu.uct.cl"
}

###############################################################################
# Locals
###############################################################################

locals {
  pool_path  = "/home/${var.host_user}/vmstore/pool"
  image_path = "/home/${var.host_user}/vmstore/images/jammy-server-cloudimg-amd64.img"

  node_ips = [
    for i in range(var.vm_count) : "${var.base_ip}.${11 + i}"
  ]
}

###############################################################################
# Proveedor
###############################################################################

provider "libvirt" {
  uri = "qemu:///system"
}

###############################################################################
# Pool de almacenamiento
# v0.7.6: path es atributo directo (sin target ni bloques)
###############################################################################

resource "libvirt_pool" "galera_pool" {
  name = "galera-pool"
  type = "dir"
  path = local.pool_path
}

###############################################################################
# Imagen base — desde archivo local
###############################################################################

resource "libvirt_volume" "ubuntu_base" {
  name   = "jammy-server-cloudimg-amd64.img"
  pool   = libvirt_pool.galera_pool.name
  source = local.image_path
  format = "qcow2"
}

###############################################################################
# Discos de nodos — copy-on-write sobre imagen base
###############################################################################

resource "libvirt_volume" "node_disk" {
  count          = var.vm_count
  name           = "galera-db${count.index + 1}.qcow2"
  pool           = libvirt_pool.galera_pool.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = var.disk_size_bytes
}

###############################################################################
# Red virtual NAT
###############################################################################

resource "libvirt_network" "galera_net" {
  name      = "galera-net"
  mode      = "nat"
  domain    = "galera.local"
  addresses = ["${var.base_ip}.0/24"]
  autostart = true

  dhcp {
    enabled = false
  }

  dns {
    enabled    = true
    local_only = true
  }
}

###############################################################################
# Cloud-init por nodo
###############################################################################

resource "libvirt_cloudinit_disk" "node_init" {
  count = var.vm_count

  name = "cloud-init-db${count.index + 1}.iso"
  pool = libvirt_pool.galera_pool.name

  meta_data = <<-EOF
    instance-id: db${count.index + 1}
    local-hostname: db${count.index + 1}
    EOF

  user_data = <<-EOF
    #cloud-config
    hostname: db${count.index + 1}
    fqdn: db${count.index + 1}.galera.local
    manage_etc_hosts: true

    users:
      - name: ubuntu
        gecos: "Ubuntu User"
        groups: sudo
        shell: /bin/bash
        sudo: "ALL=(ALL) NOPASSWD:ALL"
        lock_passwd: true
        ssh_authorized_keys:
          - ${var.ssh_public_key}

    ssh_pwauth: false
    disable_root: true

    packages:
      - qemu-guest-agent

    runcmd:
      - systemctl enable --now qemu-guest-agent
    EOF

  network_config = <<-EOF
    version: 2
    ethernets:
      ens3:
        dhcp4: false
        addresses:
          - ${local.node_ips[count.index]}/24
        gateway4: ${var.base_ip}.1
        nameservers:
          addresses:
            - 8.8.8.8
            - 1.1.1.1
    EOF
}

###############################################################################
# Dominios (VMs)
###############################################################################

resource "libvirt_domain" "galera_node" {
  count  = var.vm_count
  name   = "galera-db${count.index + 1}"
  memory = var.vm_memory_mb
  vcpu   = var.vm_vcpu

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.node_init[count.index].id

  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }

  network_interface {
    network_id = libvirt_network.galera_net.id
    hostname   = "db${count.index + 1}"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
    autoport    = true
  }

  autostart = true
}

###############################################################################
# Outputs
###############################################################################

output "node_ips" {
  description = "IPs de los nodos del clúster"
  value       = local.node_ips
}

output "ansible_inventory_hint" {
  description = "Pegar en inventory.ini"
  value = join("\n", concat(
    ["[galera_cluster]"],
    [for i in range(var.vm_count) :
      "db${i + 1} ansible_host=${local.node_ips[i]} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa"
    ]
  ))
}
