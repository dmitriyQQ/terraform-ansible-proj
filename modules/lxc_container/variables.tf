variable "hostname" {
  description = "container hostname"
  type        = string
}

variable "ip" {
  description = "ip address"
  type        = string
}

variable "target_node" {
  description = "Proxmox node name"
  type        = string
}

variable "ostemplate" {
  description = "OS template path"
  type        = string
}

variable "password" {
  description = "container root password"
  type        = string
  sensitive   = true
}

variable "memory" {
  description = "RAM"
  type        = number
  default     = 2048
}

variable "swap" {
  description = "swap in memory"
  type        = number
  default     = 512
}

variable "disk_size" {
  description = "disk size"
  type        = string
  default     = "2G"
}

variable "cores" {
  description = "CPU cores"
  type        = number
  default     = 1
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "gw" {
  description = "gateway"
  type        = string
  default     = "192.168.0.1"
}

variable "storage" {
  description = "Proxmox storage"
  type        = string
  default     = "local-lvm"
}
