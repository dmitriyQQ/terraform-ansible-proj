variable "containers" {
  description = "map of containers"
  type        = map(object({
    hostname  = string
    ip        = string
    memory    = optional(number, 2048)
    swap      = optional(number, 512)
    disk_size = optional(string, "2G")
    cores     = optional(number, 2)
  }))
  default = {}
}

variable "proxmox_api_id" {
  description = "api id"
  type  = string
  sensitive = true
}

variable "proxmox_api_secret" {
  description = "api secret"
  type  = string
  sensitive = true
}

variable "lxc_passwd" {
  description = "container password"
  type  = string
  sensitive = true
}


