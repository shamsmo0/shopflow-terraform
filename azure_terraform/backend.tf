
terraform {
  backend "azurerm" {
    access_key           = var.state.access_key
    storage_account_name = var.state.storage_account_name
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
