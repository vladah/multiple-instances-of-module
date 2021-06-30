terraform {
  required_version = "~> 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
      # configuration_aliases = [ aws.use2 ]
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
  length = 2
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
  # providers = {
  #   aws = aws.use2
  # }
}

module "server_for_each_use2" {
  source   = "./publish_instance"
  for_each = toset(["assets", "media"])



  server_name = each.key
  providers = {
    aws = aws.use2
  }
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
  provisioner "local-exec" {
    command = "date"
  }

  provisioner "local-exec" {
    command = "echo The server's IP address is ${self.private_ip}"
  }
}

output "server_names_count" {
  value = [for obj in module.server_count : "${upper(obj.ser_name)}_${uuid()}"]
}

output "server_ids_count" {
  value = module.server_count[*].ser_id
}

output "server_names_for_each" {
  value = { for key, value in module.server_for_each_use2 : key => value.ser_name }
}

output "server_ids_for_each" {
  value = values(module.server_for_each_use2)[*].ser_id
}
