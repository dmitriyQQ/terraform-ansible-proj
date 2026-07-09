output "hostname" {
  description = "container hostname"
  value = proxmox_lxc.this.hostname
}

output "ip" {
  description = "container ip"
  value = proxmox_lxc.this.network[0].ip
}
