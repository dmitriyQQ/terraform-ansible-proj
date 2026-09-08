variable "hostname" {
  description = "container hostname"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  type        = string
}

variable "platform" {
  description = "platform settings"
  type = object({
    target_node = string
    ostemplate  = string
    storage     = optional(string, "local-lvm")
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
    bridge  = optional(string, "vmbr1")
    gateway = optional(string, "192.168.100.2")
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
