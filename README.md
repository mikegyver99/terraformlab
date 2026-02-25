# terraformlab

This repository contains Terraform example(s) used for lab exercises and experimentation.  
See branches for individual projects etc. (work in progress)  

## Files Structure for DRY principles
```
terraform-project/
├── modules/                  # Reusable blueprints (The "What")
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── rds/
│   │   ├── main.tf
│   │   └── ...
│   ├── lambda/
│   │   ├── main.tf
│   │   └── ...
│   └── networking/           # VPC, Route53, etc.
│       ├── main.tf
│       └── ...
├── environments/             # Live deployments (The "Where")
│   ├── dev/
│   │   ├── main.tf           # Calls modules with dev settings
│   │   ├── variables.tf
│   │   ├── terraform.tfvars  # Dev-specific values
│   │   └── backend.tf        # S3 bucket for dev state
│   ├── qa/
│   │   └── ...
│   ├── stg/
│   │   └── ...
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars  # Production-grade scaling/sizes
│       └── backend.tf
└── README.md
```
