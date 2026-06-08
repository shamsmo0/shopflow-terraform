
terraform {
  backend "azurerm" {

    container_name = "tfstate"           # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key            = "terraform.tfstate" # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
  }
}
