module "sg" {
    source = "../../mga-terraform/sg"
}

module "s3" {
    source = "../../mga-terraform/s3"
}

module "dns" {
    source = "../../mga-terraform/dns"
}

provider "aws"
{
    region = "us-east-1"
    profile = "massgo"
}

resource "terraform_remote_state" "s3"
{
    backend = "s3"
    config
    {
        bucket = "${module.s3.tf-state}"
        key = "terraform.tfstate"
        region = "us-east-1"
        profile = "massgo"
    }
}
