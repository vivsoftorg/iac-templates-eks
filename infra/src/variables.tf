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

variable "create_kubeconfig" {
  description = "Should we create a kubeconfig file"
  type        = bool
  default     = false
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

################################################################################
# Flux IAM Role (for EKS Pod Identity)
################################################################################

variable "create_flux_iam_role" {
  description = "Controls whether to create a Flux IAM role with EKS Pod Identity trust"
  type        = bool
  default     = false
}

variable "flux_iam_role_name" {
  description = "Name of the Flux IAM role"
  type        = string
  default     = null
}

variable "flux_iam_role_path" {
  description = "Path for the Flux IAM role"
  type        = string
  default     = null
}

variable "flux_iam_role_description" {
  description = "Description of the Flux IAM role"
  type        = string
  default     = "IAM role for Flux GitOps controller with EKS Pod Identity"
}

variable "flux_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the Flux IAM role"
  type        = string
  default     = null
}

variable "flux_iam_role_tags" {
  description = "A map of additional tags to add to the Flux IAM role"
  type        = map(string)
  default     = {}
}
