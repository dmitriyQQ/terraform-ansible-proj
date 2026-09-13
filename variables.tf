variable "containers" {
  description = "map of containers"
  type = map(object({
    profile = optional(string)

    network = map(object({
      ip      = string
      bridge  = optional(string)
      gateway = optional(string)
    }))

    resources = optional(object({
      memory = optional(number, 2048)
      swap   = optional(number, 512)
      cores  = optional(number, 1)
    }))

    storage = optional(map(object({
      size = string
    })))

    groups = list(string)

  }))

  default = {}


  validation {
    condition = alltrue([
      for _, value in var.containers :
      value.resources == null
      ? true
      : value.resources.cores > 0
    ])
    error_message = "Each container must have at least one CPU core."
  }

  validation {
    condition = alltrue([
      for _, value in var.containers :
      value.resources == null
      ? true
      : value.resources.memory >= 512
    ])
    error_message = "Each container must have at least 512MB of RAM"
  }

  validation {
    condition = alltrue([
      for _, value in var.containers :
      value.profile == null
      ? true
      : contains(
        ["small", "medium", "large"],
        value.profile
      )
    ])

    error_message = "Profile must be one of: small, medium or large"
  }

  validation {
    condition = alltrue(flatten([
      for _, value in var.containers :
      value.storage == null
      ? [true]
      : [
        for _, disk in value.storage :
        can(regex("^[0-9]+G$", disk.size))
      ]
    ]))

    error_message = "Disk size must be in format: <number>G (e.g. 2G, 8G, 32G)."
  }
}

variable "proxmox_api_url" {
  description = "api url"
  type        = string
}

variable "proxmox_api_id" {
  description = "api id"
  type        = string
  sensitive   = true
}

variable "proxmox_api_secret" {
  description = "api secret"
  type        = string
  sensitive   = true
}

variable "lxc_passwd" {
  description = "container password"
  type        = string
  sensitive   = true
}

variable "target_node" {
  description = "Proxmox target node"
  type        = string
  default     = "hostname"
}

variable "ostemplate" {
  description = "OS template"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "storage" {
  description = "Proxmox storage"
  type        = string
  default     = "local-lvm"
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  type        = string
}

variable "proxmox_ssh_host" {
  description = "Address proxmox-host for Ansible ProxyJump"
  type        = string
}
