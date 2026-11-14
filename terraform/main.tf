# main.tf — Données partagées, politique de mots de passe du compte
#
# Ce fichier regroupe les éléments transverses du lab :
#   - récupération de l'identité du compte (account id),
#   - politique de mots de passe applicable à tout le compte AWS.

# Identité du compte courant (utilisée pour construire les ARN dans les policies).
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  prefix     = var.project_name
}

# -----------------------------------------------------------------------------
# Politique de mots de passe du compte
# -----------------------------------------------------------------------------
# Première brique de durcissement IAM : imposer des mots de passe robustes et
# leur rotation. Cette politique s'applique à TOUS les utilisateurs IAM du compte.
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}
