# versions.tf — Versions de Terraform et du provider AWS
#
# On épingle les versions pour garantir des `plan`/`apply` reproductibles.
# Le provider AWS v5.x est requis pour les arguments utilisés dans ce lab.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Taguer automatiquement toutes les ressources créées par ce lab,
  # ce qui facilite l'audit et le nettoyage (`terraform destroy`).
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "lab"
      ManagedBy   = "Terraform"
      Owner       = "HanaBouikni"
    }
  }
}
