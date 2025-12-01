terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.54.0"
    }
  }
  cloud {
    organization = "prasanna-projects"       
    workspaces {
      name = "terrafrom-azure" 
  }
}
}

provider "azurerm" {
  features {}
}