output "containers_info" {
  description = "output containers hostname and ip"
  value = {
    for key, value in module.container :
    key => {
      ip     = split("/", value.ip)[0]
      groups = local.containers[key].groups
    }
  }
}
