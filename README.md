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
1. You need to deploy `no-tag.p.json` policy first of all to deny any resource created without a tag, that's to mitigate unstructured archetucter. By typing the following into the terminal:
   1.  `az policy definition create --name tagging-policy --rule ./policies/no-tag.p.json` to create the policy definition.
   2.  `az policy assignment create --display-name tagging-policy --policy tagging-policy` to assign the policy to your subscription in azure cloud.
2. Deploy Packer image described in `server.json`:
   1. Create a service account by following [Microsoft Documention](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal) to get a `client_id`, `client_secret` and `subscription_id` of your azure subscription to authintecate Packer into building and uploading the image into your azure cloud.
   2. Run `packer build -var 'client_id=YOUR_CLIENT_ID' -var 'client_secret=YOUR_CLIENT_SECRET' -var 'subscription_id=YOUR_SUB_ID' server.json` and providing the variables that you got from the first step.
3. Deploy Terraform Infrastrcture described in `main.tf`:
   1. First of all you can provide the following vars to the configuration:
      * **image_name**:
        * string
        * packer image name used to create VMs.
        * (Required)
      * **prefix**:
        * string
        * Prefix of resource name.
        * (Required)
      * **vm_replicas**:
        * number
        * Indicates the number of VMs created.
        * (Optional: default to `1`)
      * **location**:
        * string
        * The location where the resources will be created at.
        * (Optional: default to `UAE North`)
      * **vn_address_space**:
        * string
        * The address space for the Virtual Network created.
        * (Optional: default to `10.0.0.0/24`)
      * **vm_size**:
        * string
        * The VM size for all vm_replicas.
        * (Optional: default to `Standard_B1s`)
      * **tags**:
        * {environment: string, namespace: string}
        * Tags that will be added to created resources.
        * (Optional: default to `{environment: "dev", namespace: "udacity"}`)
      * **image_rg**:
        * string
        * packer image resource group name.
        * (Optional: default to `packer-rg`)
      * **ssh_username**:
        * string
        * The username to loging through ssh
        * (Optional: default to `udacity`)
    1. Produce terraform plan to a file using `terraform plan -out filename.plan` and provide the required vars mentioned above.
    2. Build the infrastructure from the plan produced in step 2 by executing `terraform apply "filename.plan"`.
    3. (Optional) For those who aren't that rich like me, don't forget to destroy the infrastructure after you made sure everything went right is the **Output** section shows, by executing `terrafrom destroy`.

### Output
After following the instruction you should end up having the following number of resources in the `{prefix}` resource group:
* `vm_replicas` number of VMs
* `vm_replicas` number of OS Disks
* `vm_replicas` number of Storage Disks
* 1 Virtual Network
* 1 Loadbalancer
* 1 Public IP
* 1 VM availability set
* 1 Network Card Interface
* 1 Network Security Group

Image from Azure Portal: 
![infra]

[infra]: ./udacity-test.jpg "Azure Portal Screenshot indicating the infrastructure built using the instructions and files in this repo"
