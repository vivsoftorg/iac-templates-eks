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