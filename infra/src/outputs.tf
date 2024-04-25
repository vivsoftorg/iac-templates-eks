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
  value       = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks.cluster_name}"
}