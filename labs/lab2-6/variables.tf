variable "subscription_id" {
  type        = string
  description = "ID della subscription Azure"
}

variable "student" {
  type        = string
  description = "Sigla personale (3-8 caratteri minuscoli o numeri)"

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.student))
    error_message = "student deve avere 3-8 caratteri minuscoli o numeri."
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment deve essere dev, test o prod."
  }
}

variable "replication_type" {
  type    = string
  default = "LRS"
}
