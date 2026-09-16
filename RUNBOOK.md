# Incident Response Runbook: Suspected Unauthorized Database Access

## 1. Triage & Detection
* **Trigger:** Anomalous DB query volume alert, unauthorized role assumption in CloudTrail, or GuardDuty findings.
* **Action:** Confirm non-standard IP connections or unexpected high-volume data exfiltration queries in PostgreSQL logs.

## 2. Containment
* **Isolate Database:** Instantly update `novapay-db-sg` security group to block all inbound traffic except emergency admin bastion host.
* **Revoke Credentials:** Rotate DB password immediately in AWS Secrets Manager.
* **Terminate Active Sessions:**
  ```sql
  SELECT pg_terminate_backend(pid) 
  FROM pg_stat_activity 
  WHERE usename = 'novapay_admin' AND client_addr != 'APPROVED_IP';
3. Eradication & Recovery
Issue fresh IAM/DB credentials via automated rotation pipeline.

Inspect Terraform state logs for unexpected infrastructure modifications.

Re-deploy application nodes with verified Docker image digests.

4. Post-Incident & Compliance Reporting
Perform forensic analysis using AWS CloudTrail and VPC Flow Logs.

NDPA 2023 Compliance: If personal data (BVN, NIN, financial data) was exposed, notify the Nigeria Data Protection Commission (NDPC) within 72 hours as required by law.


