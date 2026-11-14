# users.tf — Utilisateurs IAM créés à partir des variables
#
# Les utilisateurs sont créés avec une PERMISSION BOUNDARY : leurs droits
# effectifs ne pourront jamais dépasser ce plafond, quelles que soient les
# politiques de groupe attachées par la suite.

# ---- Développeurs ------------------------------------------------------------
resource "aws_iam_user" "developers" {
  for_each = toset(var.developer_users)

  name                 = each.value
  permissions_boundary = aws_iam_policy.developer_boundary.arn

  tags = {
    Role = "developer"
  }
}

resource "aws_iam_user_group_membership" "developers" {
  for_each = aws_iam_user.developers

  user   = each.value.name
  groups = [aws_iam_group.developers.name]
}

# ---- Auditeurs ---------------------------------------------------------------
resource "aws_iam_user" "auditors" {
  for_each = toset(var.auditor_users)

  name                 = each.value
  permissions_boundary = aws_iam_policy.developer_boundary.arn

  tags = {
    Role = "auditor"
  }
}

resource "aws_iam_user_group_membership" "auditors" {
  for_each = aws_iam_user.auditors

  user   = each.value.name
  groups = [aws_iam_group.auditors.name]
}
