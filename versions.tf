terraform {
  required_providers {
    hcloud = {
      source = "terraform-providers/hcloud"
    }
    local = {
      source = "hashicorp/local"
    }
  }
  required_version = ">= 0.13"
}
