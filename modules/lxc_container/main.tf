resource "proxmox_lxc" "this" {
  hostname = var.hostname
  target_node = var.target_node
  ostemplate = var.ostemplate
  password = var.password

  cores = var.cores
  memory = var.memory
  swap = var.swap

  rootfs {
    storage = var.storage
    size = var.disk_size
  }

  network {
    name = "eth0"
    bridge = var.bridge
    ip = var.ip
    gw = var.gw
  }
  start = true
}
