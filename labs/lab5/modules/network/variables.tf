variable "name_prefix" {
  type        = string
  description = "Prefisso per i nomi delle risorse"
}

variable "resource_group_name" {
  type        = string
  description = "Nome del resource group"
}

variable "location" {
  type        = string
  description = "Location delle risorse"
}

variable "address_space" {
  type = set(string)
}

variable "subnets" {
  type = map(object({
    cidr = string
  }))
  description = "Mappa nome subnet -> CIDR"
}

variable "tags" {
  type    = map(string)
  default = {}
}
