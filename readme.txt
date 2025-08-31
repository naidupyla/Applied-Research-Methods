his repository demonstrates Policy-as-Code (PaC) using Terraform and Open Policy Agent (OPA) to enforce compliance and security rules on infrastructure-as-code deployments.

 Overview

Terraform is used to define cloud resources (Azure in this demo).

OPA/Rego policies are written to validate the Terraform plan.

The workflow ensures that insecure or non-compliant infrastructure does not get deployed.

This project shows how to shift security left by automatically validating infrastructure-as-code.

🗂️ Project Structure
PAC-Final-Demo/
│── check_plan.sh              # Script to run OPA checks on Terraform plans
│── tfplan.json                # Example Terraform plan output
│── kv.rego                    # Key Vault policy
│── nsg.rego                   # Network Security Group policy
│── stg1.rego                  # Storage policy (variant 1)
│── stgtest.rego               # Storage test policy
│
├── insecure/                  # Example insecure Terraform configuration
│   ├── main.tf                 # Terraform resources
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── terraform.tfstate       # Terraform state
│   └── tfplan.json             # Terraform plan for testing
│
└── policies/                  # Collection of OPA policies
    ├── storage.rego
    ├── storage1.rego
    ├── vm.rego
    └── vnet_subnet.rego

⚙️ Prerequisites

Terraform
 (v1.x or later)

OPA (Open Policy Agent)
 (v0.50+ recommended)

Azure CLI (if you want to deploy resources, optional)

 Usage
1. Initialize Terraform
cd insecure
terraform init

2. Generate a Terraform Plan
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

3. Run OPA Policy Checks

From the project root:

opa eval --input insecure/tfplan.json --data policies --format pretty "data"


Or use the helper script:

./check_plan.sh


This will evaluate the Terraform plan against the defined OPA policies.