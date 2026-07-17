locals {
  platform = {
    target_node = var.target_node
    ostemplate  = var.ostemplate
    storage     = var.storage
  }

  profiles = {
    small = {
      resources = {
        memory = 1024
        swap   = 512
        cores  = 1
      }

      storage = {
        root = {
          size = "2G"
        }
      }
    }

    medium = {
      resources = {
        memory = 2048
        swap   = 1024
        cores  = 2
      }

      storage = {
        root = {
          size = "4G"
        }
      }
    }

    large = {
      resources = {
        memory = 4096
        swap   = 2048
        cores  = 4
      }

      storage = {
        root = {
          size = "8G"
        }
      }
    }

  }

  containers = {
    for key, value in var.containers :
    key => merge(
      value,

      {
        resources = merge(
          value.profile != null
          ? local.profiles[value.profile].resources
          : {},

          value.resources != null
          ? value.resources
          : {},
        )

        storage = merge(
          value.profile != null
          ? local.profiles[value.profile].storage
          : {},

          value.storage != null
          ? value.storage
          : {},
        )
      }
    )
  }
}

