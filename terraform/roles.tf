# roles.tf — Rôle auditeur en lecture seule, assumable uniquement avec MFA
#
# Illustration du modèle "assume-role" : plutôt que d'attacher des droits
# permanents, l'auditeur assume un rôle temporaire. La trust policy exige une
# authentification MFA et une session courte, réduisant la fenêtre d'exposition.

data "aws_iam_policy_document" "auditor_trust" {
  statement {
    sid     = "AllowAccountUsersToAssumeWithMFA"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    # Exiger une session MFA pour assumer le rôle.
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "auditor" {
  name               = "${local.prefix}-auditor"
  description        = "Rôle de lecture seule, assumable par les auditeurs authentifiés en MFA."
  assume_role_policy = data.aws_iam_policy_document.auditor_trust.json
  # Pas de permission boundary ici : le rôle ne porte que ReadOnlyAccess (sûr par
  # nature) et sa trust policy exige déjà le MFA. Lui appliquer la boundary des
  # développeurs plafonnerait l'audit au seul périmètre applicatif, ce qui est
  # contraire à l'objectif d'un rôle d'audit en lecture seule.
  max_session_duration = 3600 # 1 heure
}

# Droits de lecture seule à l'échelle du compte (politique AWS managée).
resource "aws_iam_role_policy_attachment" "auditor_readonly" {
  role       = aws_iam_role.auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
