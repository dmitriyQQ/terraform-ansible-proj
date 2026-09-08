resource "proxmox_lxc" "this" {
  hostname        = var.hostname
  target_node     = var.platform.target_node
  ostemplate      = var.platform.ostemplate
  password        = var.password
  ssh_public_keys = var.ssh_public_key

  cores  = var.resources.cores
  memory = var.resources.memory
  swap   = var.resources.swap

  rootfs {
    storage = var.platform.storage
    size    = var.storage["root"].size
  }

  dynamic "network" {
    for_each = var.network
    content {
      name   = network.key
      bridge = network.value.bridge
      ip     = network.value.ip
      gw     = network.value.gateway
    }
  }
  start = true
}
