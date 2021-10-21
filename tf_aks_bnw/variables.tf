variable "project-name" {
  description = "Funny name this all belongs to"
  default     = "megusta"
}

variable "postfix" {
  description = "Randon stuff to add everywhere"
  default     = "-an12"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to install"
  default     = "1.20.9"
}

variable "aks_admin_group_objectids" {
  description = "Object IDs of groups to be added to the Aks Admin Role"
  default     = ["d095b256-5ac9-480d-923a-2c6ca0825ffe"]
}

variable "location" {
  description = "Location of the cluster."
  default     = "westeurope"
}

variable "virtual_network_address_prefix" {
  description = "VNET address prefix"
  default     = "15.0.0.0/8"
}

variable "aks_subnet_address_prefix" {
  description = "Subnet address prefix."
  default     = "15.0.0.0/16"
}

variable "app_gateway_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "15.1.0.0/16"
}

variable "aks_name" {
  description = "AKS cluster name"
  default     = "aks-cluster1"
}

variable "aks_service_cidr" {
  description = "CIDR notation IP range from which to assign service cluster IPs"
  default     = "10.0.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "DNS server IP address"
  default     = "10.0.0.10"
}
