variable "hostname" {
  description = "container hostname"
  type        = string
}

variable "platform" {
  description = "platform settings"
  type = object({
    target_node = string
    ostemplate  = string
    storage = optional(string, "local-lvm")
  })
}

variable "password" {
  description = "container root password"
  type        = string
  sensitive   = true
}

variable "network" {
  description = "Network variables"
  type = map(object({
    ip      = string
    bridge  = optional(string, "vmbr0")
    gateway = optional(string, "192.168.0.1")
  }))
}

variable "resources" {
  description = "Resources variables"
  type = object({
    memory = optional(number, 2048)
    swap   = optional(number, 512)
    cores  = optional(number, 1)
  })
}

variable "storage" {
  description = "Storage variables"
  type = map(object({
    size = string
  }))
}
