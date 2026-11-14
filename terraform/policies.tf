# policies.tf — Politiques IAM gérées (customer managed policies)
#
# On privilégie des politiques "customer managed" écrites au moindre privilège
# plutôt que les politiques AWS managées trop larges (ex. AdministratorAccess).
# Chaque document est défini via aws_iam_policy_document : Terraform en valide
# la syntaxe au `plan` et le rendu JSON reste lisible.

# =============================================================================
# 1) Politique "Enforce MFA" — self-service des identifiants + blocage sans MFA
# =============================================================================
# Pattern de référence AWS : l'utilisateur peut gérer SES propres identifiants
# (mot de passe, clés d'accès, périphérique MFA), mais TOUT le reste est refusé
# tant qu'il n'est pas connecté avec une authentification multi-facteurs.
data "aws_iam_policy_document" "enforce_mfa" {

  statement {
    sid       = "AllowViewAccountInfo"
    effect    = "Allow"
    actions   = ["iam:GetAccountPasswordPolicy", "iam:ListVirtualMFADevices"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManageOwnPasswords"
    effect = "Allow"
    actions = [
      "iam:ChangePassword",
      "iam:GetUser",
    ]
    resources = ["arn:aws:iam::${local.account_id}:user/$${aws:username}"]
  }

  statement {
    sid    = "AllowManageOwnAccessKeys"
    effect = "Allow"
    actions = [
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey",
      "iam:GetAccessKeyLastUsed",
    ]
    resources = ["arn:aws:iam::${local.account_id}:user/$${aws:username}"]
  }

  statement {
    sid    = "AllowManageOwnMFA"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListMFADevices",
      "iam:DeactivateMFADevice",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:mfa/$${aws:username}",
      "arn:aws:iam::${local.account_id}:user/$${aws:username}",
    ]
  }

  # Verrou principal : refuser toute action autre que la gestion de ses propres
  # identifiants tant que la session n'est pas MFA. Activable via var.force_mfa.
  dynamic "statement" {
    for_each = var.force_mfa ? [1] : []
    content {
      sid    = "DenyAllExceptSelfManageUnlessMFA"
      effect = "Deny"
      not_actions = [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:GetUser",
        "iam:ListMFADevices",
        "iam:ListVirtualMFADevices",
        "iam:ResyncMFADevice",
        "iam:ChangePassword",
        "iam:GetAccountPasswordPolicy",
        "sts:GetSessionToken",
      ]
      resources = ["*"]

      condition {
        test     = "BoolIfExists"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["false"]
      }
    }
  }
}

resource "aws_iam_policy" "enforce_mfa" {
  name        = "${local.prefix}-enforce-mfa"
  description = "Self-service des identifiants et blocage de toute action sans MFA."
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}

# =============================================================================
# 2) Permission boundary — plafond de permissions anti-escalade de privilèges
# =============================================================================
# Une permission boundary ne DONNE pas de droits : elle plafonne les droits
# effectifs maximum d'une identité. Même si un développeur se voyait attacher
# AdministratorAccess par erreur, il resterait confiné à ce plafond.
data "aws_iam_policy_document" "developer_boundary" {

  # Plafond : services autorisés au maximum pour un développeur.
  statement {
    sid    = "AllowedServicesCeiling"
    effect = "Allow"
    actions = [
      "s3:*",
      "ec2:Describe*",
      "cloudwatch:*",
      "logs:*",
      "sts:AssumeRole",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }

  # Autoriser la gestion de ses propres identifiants (sinon la boundary
  # bloquerait aussi l'enrôlement MFA exigé par enforce_mfa).
  statement {
    sid    = "AllowSelfCredentialManagement"
    effect = "Allow"
    actions = [
      "iam:*AccessKey*",
      "iam:ChangePassword",
      "iam:*MFADevice*",
      "iam:GetUser",
      "iam:ListMFADevices",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:user/$${aws:username}",
      "arn:aws:iam::${local.account_id}:mfa/$${aws:username}",
    ]
  }

  # Garde-fou explicite : interdire les actions d'escalade de privilèges,
  # même si une autre politique tentait de les accorder.
  statement {
    sid    = "DenyPrivilegeEscalation"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateRole",
      "iam:AttachUserPolicy",
      "iam:AttachRolePolicy",
      "iam:PutUserPolicy",
      "iam:PutRolePolicy",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeleteUserPermissionsBoundary",
      "iam:DeleteRolePermissionsBoundary",
      "iam:PutUserPermissionsBoundary",
      "iam:PutRolePermissionsBoundary",
      "organizations:*",
      "account:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "developer_boundary" {
  name        = "${local.prefix}-developer-boundary"
  description = "Permission boundary plafonnant les droits et bloquant l'escalade de privilèges."
  policy      = data.aws_iam_policy_document.developer_boundary.json
}

# =============================================================================
# 3) Politique "Developers" — droits applicatifs au moindre privilège
# =============================================================================
# Accès restreint à un seul bucket S3 (préfixe applicatif) + lecture EC2/logs.
data "aws_iam_policy_document" "developers" {

  statement {
    sid       = "ListOwnBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${var.lab_bucket_name}"]
  }

  statement {
    sid    = "ReadWriteObjectsInOwnBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${var.lab_bucket_name}/*"]
  }

  statement {
    sid    = "ReadOnlyObservability"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "cloudwatch:GetMetricData",
      "cloudwatch:ListMetrics",
      "logs:GetLogEvents",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "developers" {
  name        = "${local.prefix}-developers"
  description = "Droits développeurs restreints : S3 sur un bucket dédié + observabilité en lecture."
  policy      = data.aws_iam_policy_document.developers.json
}

# =============================================================================
# 4) Politique "Auditors" — lecture seule + droit d'assumer le rôle auditeur
# =============================================================================
data "aws_iam_policy_document" "auditors" {

  statement {
    sid    = "AssumeAuditRole"
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [aws_iam_role.auditor.arn]
  }
}

resource "aws_iam_policy" "auditors" {
  name        = "${local.prefix}-auditors"
  description = "Autorise les auditeurs à assumer le rôle de lecture seule (avec MFA)."
  policy      = data.aws_iam_policy_document.auditors.json
}
