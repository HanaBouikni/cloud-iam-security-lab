# groups.tf — Groupes IAM et rattachement des politiques
#
# Bonne pratique : attacher les politiques à des GROUPES, jamais directement
# aux utilisateurs. On gère ainsi les droits par rôle fonctionnel, et un
# nouvel arrivant hérite des bons droits par simple ajout au groupe.

# ---- Groupe développeurs -----------------------------------------------------
resource "aws_iam_group" "developers" {
  name = "${local.prefix}-developers"
}

resource "aws_iam_group_policy_attachment" "developers_app" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developers.arn
}

resource "aws_iam_group_policy_attachment" "developers_mfa" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

# ---- Groupe auditeurs --------------------------------------------------------
resource "aws_iam_group" "auditors" {
  name = "${local.prefix}-auditors"
}

resource "aws_iam_group_policy_attachment" "auditors_assume" {
  group      = aws_iam_group.auditors.name
  policy_arn = aws_iam_policy.auditors.arn
}

resource "aws_iam_group_policy_attachment" "auditors_mfa" {
  group      = aws_iam_group.auditors.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}
