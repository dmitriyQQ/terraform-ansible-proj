resource "proxmox_lxc" "simple_container" {
  for_each = var.containers

  hostname = each.value.hostname
  target_node = "hostname"
  ostemplate  = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  password    = var.lxc_passwd

  cores  = each.value.cores
  memory = each.value.memory
  swap   = each.value.swap
  
  rootfs {
    storage = "local-lvm"
    size    = each.value.disk_size
  }

  network {
    name = "eth0"
    bridge = "vmbr0"
    ip = each.value.ip
    gw = "192.168.0.1"
  }


start = true
}
