output "containers_info" {
  description = "output containers hostname and ip"
  value = {
    for key, value in module.container :
    key => {
      hostname = value.hostname
      ip       = value.ip
    }
  }
}
