output "containers_info" {
  description = "output containers hostname and ip"
  value = {
    for key, value in proxmox_lxc.simple_container :
    key => {
      hostname = value.hostname
      ip       = value.network[0].ip
    }
  }
}

