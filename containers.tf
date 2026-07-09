module "container" {
  source   = "./modules/lxc_container"
  for_each = var.containers

  hostname    = each.value.hostname
  ip          = each.value.ip
  memory      = each.value.memory
  swap        = each.value.swap
  disk_size   = each.value.disk_size
  cores       = each.value.cores

  target_node = var.target_node
  ostemplate  = var.ostemplate
  password    = var.lxc_passwd
}
