variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Regione AWS"
}

variable "student" {
  type        = string
  description = "Sigla personale (3-8 caratteri minuscoli o numeri)"

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.student))
    error_message = "student deve avere 3-8 caratteri minuscoli o numeri."
  }
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment deve essere dev, test o prod."
  }
}

variable "versioning_status" {
  type    = string
  default = "Enabled"

  validation {
    condition     = contains(["Enabled", "Suspended"], var.versioning_status)
    error_message = "versioning_status deve essere Enabled o Suspended."
  }
}
