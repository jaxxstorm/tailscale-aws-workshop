# Tailscale AWS Workshop

Welcome to the Tailscale AWS Workshop! In this hands-on workshop, you'll learn how to securely access AWS resources using Tailscale's zero-trust networking capabilities.

## What You'll Learn

In this workshop, you will:

1. **[Prerequisites](prereq.md)**
   - Set up Git, AWS CLI, Terraform, and Tailscale on your local machine
   - Configure and validate your AWS credentials

2. **[Provision Base Infrastructure](provision.md)**
   - Create a VPC with public and private subnets using Terraform
   - Deploy an RDS PostgreSQL database in a private subnet

3. **[Manually Provision a Subnet Router](subnet-router.md)**
   - Launch an EC2 instance in a public subnet
   - Install and configure Tailscale as a subnet router
   - Advertise routes to access private VPC resources
   - Validate connectivity to the RDS database from your local machine

4. **[Automate Subnet Router Provisioning](automated-subnet-router.md)**
   - Create Tailscale auth keys and tags
   - Use Terraform and cloud-init to automatically provision subnet routers
   - Configure auto-approval for advertised routes
   - Set up resilient, self-healing infrastructure with Auto Scaling Groups

5. **[Connectivity Testing](connectivity-testing.md)**
   - Understand the difference between direct and relayed connections
   - Use `tailscale ping` to diagnose connection types
   - Configure security groups for optimal direct connections

6. **[Configure a Peer Relay](peer-relay.md)**
   - Set up a Tailscale peer relay for private subnet clients
   - Configure ACL policies for peer relay access
   - Achieve high-performance connections to private instances

7. **[Additional Features](additional-features.md)**
   - Enable and use Tailscale SSH for keyless access
   - Configure an exit node to route all traffic through AWS

By the end of this workshop, you'll understand how to leverage Tailscale to create secure, seamless connections to your private AWS infrastructure without exposing it to the public internet.

