# AI Usage & Oversight Report

## 1. Tools Used
- GitHub Copilot & ChatGPT for scaffolding Terraform configurations, writing Dockerfiles, and structuring GitHub Actions workflows.

## 2. Sample Prompts
1. *"Write a multi-stage Dockerfile for a Go microservice that outputs a small image size."*
2. *"Generate an AWS Terraform script for an RDS PostgreSQL instance and an IAM policy for Secrets Manager access."*

## 3. Insecure Defaults Caught & Remediated
- **Insecure AI Output (IAM Policy):**
  The AI generator produced an overly permissive wildcard policy:
  ```hcl
  Statement = [{
    Effect   = "Allow"
    Action   = "secretsmanager:*"
    Resource = "*"
  }]
Remediation: Refactored the policy to strictly adhere to least privilege: scoped actions to secretsmanager:GetSecretValue and explicitly bound Resource to the exact Secret ARN (aws_secretsmanager_secret.db_credentials.arn).

Insecure AI Output (Dockerfile):
The initial AI snippet omitted user creation and executed the Go binary as root.

Remediation: Added addgroup and adduser directives in the Alpine stage and explicitly declared USER novapay:novapay.