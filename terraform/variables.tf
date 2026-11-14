# variables.tf — Variables d'entrée du lab
#
# Toutes les valeurs sont surchargeables via un fichier terraform.tfvars
# (voir terraform.tfvars.example).

variable "aws_region" {
  description = "Région AWS cible. IAM est un service global, mais le provider exige une région."
  type        = string
  default     = "eu-west-3" # Paris
}

variable "project_name" {
  description = "Préfixe appliqué aux noms de ressources et aux tags, pour éviter les collisions."
  type        = string
  default     = "iam-lab"
}

variable "developer_users" {
  description = "Liste des utilisateurs IAM placés dans le groupe 'developers' (droits restreints)."
  type        = list(string)
  default     = ["dev.alice", "dev.bob"]
}

variable "auditor_users" {
  description = "Liste des utilisateurs IAM placés dans le groupe 'auditors' (lecture seule + assume-role)."
  type        = list(string)
  default     = ["audit.carol"]
}

variable "lab_bucket_name" {
  description = <<-EOT
    Nom du bucket S3 fictif sur lequel les développeurs ont des droits restreints.
    Ce lab NE crée PAS le bucket : seule la politique IAM y fait référence.
    Remplacez par un nom réel si vous voulez tester les permissions de bout en bout.
  EOT
  type        = string
  default     = "iam-lab-devs-sandbox"
}

variable "force_mfa" {
  description = "Si vrai, les utilisateurs ne peuvent (presque) rien faire tant qu'ils ne sont pas authentifiés en MFA."
  type        = bool
  default     = true
}
