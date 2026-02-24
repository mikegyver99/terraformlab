# terraformlab

This repository contains Terraform example(s) used for lab exercises and experimentation.

## Files

- [1_userdata.tf](1_userdata.tf): Example Terraform configuration that demonstrates providing instance startup configuration via user-data (cloud-init or shell script). Typically this file will create one or more virtual machine instances (for example an EC2 instance on AWS) and attach a `user-data` payload so the instance can bootstrap itself on first boot. Review the file before applying to see which provider and resources are used.

> Note: Files are prefixed with a number (e.g. `1_`) to indicate ordering or grouping for lab steps. Additional numbered `.tf` files may be added to represent subsequent steps.

## Usage

1. Install and configure the Terraform CLI for your platform.
2. Configure provider credentials (for example AWS, Azure, GCP) as required by the Terraform configuration in the repo.
3. Initialize the working directory and apply the configuration:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

4. When you're finished, destroy the created resources to avoid ongoing charges:

```bash
terraform destroy
```

Always review the contents of the `.tf` files before running `apply` so you understand what will be created and any external dependencies.

## Next steps

- If you'd like, I can:
	- Add variable definitions and a `terraform.tfvars` example.
	- Add a provider example (AWS/Azure/GCP) and documentation for credentials.
	- Split or document additional lab steps into numbered `.tf` files.

If you want one of these, tell me which and I'll add it.

## AWS-specific notes and safety (this repo uses the AWS provider)

The file [1_userdata.tf](1_userdata.tf#L1-L400) in this repo uses the `hashicorp/aws` provider and creates an EC2 instance, an S3 bucket, and a security group. Below are provider-specific prerequisites, safety advice, and tips to run this safely.

- **Prerequisites:**
	- Install the Terraform CLI.
	- Configure AWS credentials. The configuration can come from the AWS CLI (`aws configure`) or environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION`.
	- Alternatively set the region inside the provider block in `1_userdata.tf` or export `AWS_REGION`.

- **Init & apply (example):**

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

- **Safe cleanup:**

```bash
terraform destroy -auto-approve
```

- **Security cautions:**
	- The security group in `1_userdata.tf` currently allows `0.0.0.0/0` for SSH (port 22) and HTTP (port 80). Restrict SSH to your IP before applying in a real environment by editing the `cidr_blocks` for the SSH ingress to your address (for example `"203.0.113.5/32"`).
	- The EC2 instance resource in the example does not specify a `key_name`, so SSH access is not possible until you add a key pair. To SSH in, add `key_name = "<your-keypair>"` to the `aws_instance` resource and ensure the key pair exists in the target region.
	- The S3 bucket is created with default settings. If you intend to store real data, explicitly configure `bucket`, `acl`, and block public access settings. Consider `force_destroy = true` only when you understand the consequences for non-empty buckets.

- **Behavioral notes:**
	- The `user_data` script includes `sleep 300` which delays boot-time provisioning; this was likely added to simulate long-running startup actions. Expect the instance to take several minutes to finish the user-data script.
	- The AMI is obtained via an SSM parameter in the file; this selects the latest Amazon Linux 2 AMI for the selected region.

- **Outputs:**
	- After apply, run `terraform output instance_public_ip` to get the instance public IP and browse to `http://<ip>` to see the generated HTML page. The S3 bucket name is available via `terraform output bucket_name`.

- **Least privilege & cost control:**
	- Use an IAM user/role with minimal permissions required for the resources you create. Test in an isolated account if possible.
	- Remember to destroy resources when finished to avoid ongoing charges.

If you want, I can:
- Add a minimal `terraform.tfvars` and `variables.tf` to let you set `region`, `allowed_ssh_cidr`, and a `key_name` safely.
- Harden the `aws_s3_bucket` resource with recommended settings and add `force_destroy` optionally behind a variable.

Tell me which improvement you'd like and I'll add it.
