# Prerequisites

To successfully complete this workshop, ensure you have the following tools and configurations set up:

## 1. Git

- You should have Git installed on your local machine
- Verify your installation by running:
  ```bash
  git --version
  ```

## 2. An AWS Account

- You should have an AWS account with valid administrator credentials
- **AWS CLI**: Install the [AWS CLI](https://aws.amazon.com/cli/) to interact with AWS services
- **Configure Credentials**: Set up your AWS credentials using `aws configure` or environment variables
- **Validate Credentials**: Verify your AWS credentials are working by running:
  ```bash
  aws sts get-caller-identity
  ```
  This command should return your AWS account ID, user ID, and ARN

## 3. Tailscale Account

- **Sign Up**: If you don't already have a Tailscale account, [sign up here](https://login.tailscale.com/start?source=k8s-workshop).
- **Install Tailscale**: Install Tailscale on your local machine by following the [installation guide](https://tailscale.com/download)
- Tailscale will be used to connect to resources in your AWS account

## 4. Terraform Installed

- **Install Terraform**: Download and install [Terraform](https://www.terraform.io/downloads) or [OpenTofu](https://opentofu.org/docs/intro/install/)

- **Verify Installation**: Check your Terraform installation by running:
  ```bash
  terraform version
  ```
- **Note**: We will store Terraform state locally for this workshop. Make sure to add the following to your `.gitignore`:
  ```
  # Terraform state files
  *.tfstate
  *.tfstate.*
  .terraform/
  .terraform.lock.hcl
  ```


