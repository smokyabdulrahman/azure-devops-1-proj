variable "vm_replicas" {
  type        = number
  description = "Indicates the number of VMs created."
  default     = 1
}

variable "prefix" {
  type        = string
  description = "Prefix of resource name."
}

variable "location" {
  type        = string
  description = "The location where the resources will be created at."
  default     = "UAE North"
}

variable "vn_address_space" {
  type        = string
  description = "The address space for the Virtual Network created."
  default     = "10.0.0.0/24"
}

variable "vm_size" {
  type        = string
  description = "The VM size for all vm_replicas."
  default     = "Standard_B1s"
}

variable "tags" {
  type = object({
    environment = string
    namespace   = string
  })
  description = "Tags that will be added to created resources."
  default = {
    environment = "dev"
    namespace   = "udacity"
  }
}

variable "image_rg" {
  type        = string
  description = "packer image resource group name"
  default     = "packer-rg"
}

variable "image_name" {
  type        = string
  description = "packer image name used to create VMs"
}

variable "application_port" {
  type = number
  default = 80
}

variable "ssh_username" {
  type = string
  description = "The username to loging through ssh"
  default = "udacity"
}