variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default     = "project1"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "eastus"
}

variable "packer_resource_group_name" {
  description = "Name of the resource group in which the Packer image will be created"
  default     = "Udacity-Project1"
}

variable "packer_image_name" {
  description = "Name of the Packer image"
  default     = "LinuxPackerImage"
}

variable "application_port" {
  description = "Port that you want to expose to the external load balancer"
  default     = 80
}

variable "admin_user" {
  description = "User name to use as the admin account on the VMs that will be part of the VM scale set"
  default     = "azureuser"
}

variable "admin_password" {
  description = "Default password for admin account"
}

variable "tags" {
  description = "Map of the tags to use for the resources that are deployed"
  type        = map(string)
  default = {
    Environment = "Production",
    Task        = "Project1"
  }
}

variable "capacity" {
  description = "Number of capacity for VMSS"
  default     = 2
}