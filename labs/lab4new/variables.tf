variable "subscription_id" {
  type = string
}

variable "student" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.student))
    error_message = "student deve avere 3-8 caratteri minuscoli o numeri."
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnets" {
  type = map(object({
    cidr = string
  }))
  default = {
    web     = { cidr = "10.0.1.0/24" }
    backend = { cidr = "10.0.3.0/24" }
    db      = { cidr = "10.0.2.0/24" }
  }
}

variable "allowed_ports" {
  type    = list(number)
  default = [22, 80]
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2ts_v2"
  description = "Se la SKU non è disponibile: az vm list-skus -l westeurope --size Standard_B -o table"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
