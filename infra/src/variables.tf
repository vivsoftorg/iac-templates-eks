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