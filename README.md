# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction

For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started

1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies

1. Create an [Azure Account](https://portal.azure.com)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

1. Modify Packer template server.json for Environment variables
2. [Create Azure credentials](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer) for client_id and client_secret
3. Make sure specified resource group is already created in server.json
4. Run **_packer build server.json_** to build Linux Image
5. Change variables.tf as your requirements e.g, change default value of varible **_prefix_**
6. You can also add or remove variables from variables.tf but remember to change them in main.tf also
7. Run **_terraform init_** if command is not recognized, try to add terraform exe folder in the Path of Environment variables
8. Run **_terraform plan -out solution.plan_** to check the plan
9. Run **_terraform apply_** to deploy your infrastructure
10. Don't forget to run **_terraform destroy_** if created resources are unnecessary anymore

### Output

The following resources will be created when you run **_terraform apply_**

1. **_LinuxPackerImage_** in **_Udacity-Project1_** rg
2. Resource Group **_project1-resources_**
3. Virtual Network **_project1-network_**
4. Subnet **_internal_**
5. Network Interface **_project1-nic_**
6. Network Security Group **_nsg-for-project1_**
7. Public IP
8. Load Balancer
9. VMSS with managed disk
