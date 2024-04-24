variable "instance_types" {
  description = "EKS managed node instance type"
  type        = list(any)
  default     = ["t3.large"]
}

variable "eks_node_groups_min_size" {
  description = "EKS managed node "
  type        = string
  default     = 1
}

variable "eks_node_groups_max_size" {
  description = "EKS managed node "
  type        = string
  default     = 1
}

variable "eks_node_groups_desired_size" {
  description = "EKS managed node "
  type        = string
  default     = 1
}

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "create_registry1_mirror" {
  description = "Should we add the registry1 mirror to the EKS cluster nodes"
  type        = bool
  default     = false
}

variable "registry1_mirror_proxy_address" {
  description = "The address of the registry1 mirror proxy, if the registry1 mirror is enabled by setting the create_registry1_mirror"
  type        = string
  default     = "http://44.210.192.97:5000"
}
