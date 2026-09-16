# NovaPay STRIDE Threat Model

| Threat Category | Threat Scenario | Mitigation Strategy |
| :--- | :--- | :--- |
| **Spoofing** | Unauthorized API requests on balance transfer. | JWT/OAuth2 verification & BVN/NIN bound sessions. |
| **Tampering** | Floating-point rounding errors in NGN balance calculations. | Balances stored and processed exclusively in **Kobo** integer values. |
| **Repudiation** | User denies authorizing a P2P transfer or loan request. | Immutable, append-only transaction logging with cryptographic hashes. |
| **Information Disclosure** | Leak of PII (BVN, NIN, transaction history) from DB. | Field-level AES-256 encryption; storage encryption via AWS KMS; TLS 1.3 in transit. |
| **Denial of Service** | L7 flooding against USSD (*894#) API gateway integration. | Rate-limiting per user/IP using AWS WAF and Redis token buckets. |
| **Elevation of Privilege** | Container breakout or excessive AWS permissions. | Non-root container runtime; zero wildcard policies in IAM. |