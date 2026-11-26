variable "name_prefix" {
  type        = string
  description = "Prefisso per i nomi delle risorse"
}

variable "vpc_cidr" {
  type = string
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
