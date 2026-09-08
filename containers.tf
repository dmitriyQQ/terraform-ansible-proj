module "container" {
  source   = "./modules/lxc_container"
  for_each = local.containers

  hostname  = each.key
  network   = each.value.network
  resources = each.value.resources
  storage   = each.value.storage

  platform       = local.platform
  password       = var.lxc_passwd
  ssh_public_key = var.ssh_public_key
}
