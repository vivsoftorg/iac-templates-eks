output "vpc" {
  value = module.vpc
}

output "eks" {
  value = module.eks
}

output "bigbang_sops_config" {
  value = <<SOPS
  ---
creation_rules:
  - kms: ${module.eks.kms_key_arn}
    encrypted_regex: "^(data|stringData)$"
  SOPS
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${data.aws_region.current.id} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "flux_iam_role_arn" {
  description = "ARN of the Flux IAM role for EKS Pod Identity"
  value       = var.create_flux_iam_role ? aws_iam_role.flux[0].arn : null
}