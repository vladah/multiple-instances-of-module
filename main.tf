terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "myorgvh"

    workspaces {
      name = "multiple-instances-of-module"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}

provider "random" {
  # Configuration options
}

resource "random_pet" "s3_name" {
  length = 4
}

module "bucket_for_each" {
  for_each = toset(["assets", "media"])
  source   = "./publish_bucket"
  name     = "${each.key}-${random_pet.s3_name.id}"
}

module "bucket_count_use2" {
  count  = 2
  source = "./publish_bucket"
  name   = "${count.index}-${random_pet.s3_name.id}"
  providers = {
    aws = aws.use2
  }
}

module "server_for_each_use2" {
  source   = "./publish_instance"
  for_each = toset(["assets", "media"])

  server_name = each.key
  #   providers = {
  #     aws = aws.use2
  #   }
}

locals {
  server_name_list = ["assets", "media"]
}

module "server_count" {
  source = "./publish_instance"
  count  = terraform.workspace == "default" ? length(local.server_name_list) : 0

  server_name = "${local.server_name_list[count.index]}-${terraform.workspace}-${random_pet.s3_name.id}"
  #   providers = {
  #     aws = aws.use2
  #   }
}

resource "null_resource" "quiz-experts" {
  triggers = {
    uuid = uuid()
  }
  provisioner "local-exec" {
    command = "echo \"Hello, $(whoami)\""
  }
}

output "server_names_for_each" {
  value = [for key, value in module.server_for_each_use2 : value.ser_name]
}

output "server_names_count" {
  value = [for obj in module.server_count : obj.ser_name]
}
