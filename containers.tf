module "container" {
  source   = "./modules/lxc_container"
  for_each = local.containers

  hostname  = each.value.hostname
  network   = each.value.network
  resources = each.value.resources
  storage   = each.value.storage

  platform = local.platform
  password = var.lxc_passwd
}
