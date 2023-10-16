# Terraform AWS RDS PostgreSQL Deployment

This project uses Terraform to automate the deployment of a single Amazon RDS instance with PostgreSQL on AWS. Amazon RDS (Relational Database Service) is a managed relational database service that makes it easy to deploy, operate, and scale databases.

## Prerequisites

Before you begin, ensure you have the following prerequisites:

- [Terraform](https://www.terraform.io/) (verify with `terraform --version`)
- [AWS CLI](https://aws.amazon.com/cli/) configured with valid credentials
- Internet access

## Configuration

1. Clone this repository:

   ```bash
   git clone https://github.com/lfneves/infra-rds-terraform.git
   ```

region             = "us-east-1"
db_instance_name   = "postgresdb"
db_engine          = "postgres"
db_instance_class  = "db.t3.micro"
