# outputs.tf — Valeurs utiles affichées après `terraform apply`

output "account_id" {
  description = "Identifiant du compte AWS utilisé pour le lab."
  value       = local.account_id
}

output "developer_user_names" {
  description = "Utilisateurs IAM créés dans le groupe développeurs."
  value       = [for u in aws_iam_user.developers : u.name]
}

output "auditor_user_names" {
  description = "Utilisateurs IAM créés dans le groupe auditeurs."
  value       = [for u in aws_iam_user.auditors : u.name]
}

output "group_arns" {
  description = "ARN des groupes IAM."
  value = {
    developers = aws_iam_group.developers.arn
    auditors   = aws_iam_group.auditors.arn
  }
}

output "policy_arns" {
  description = "ARN des politiques IAM gérées créées par le lab."
  value = {
    enforce_mfa        = aws_iam_policy.enforce_mfa.arn
    developer_boundary = aws_iam_policy.developer_boundary.arn
    developers         = aws_iam_policy.developers.arn
    auditors           = aws_iam_policy.auditors.arn
  }
}

output "auditor_role_arn" {
  description = "ARN du rôle auditeur en lecture seule (à assumer avec MFA)."
  value       = aws_iam_role.auditor.arn
}
