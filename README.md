# Kubernetes_Docker_registry

## File Structure:

```
Kubernetes_Docker_registry/
└── terraform/
    ├── backend/
    │     └── s3-backend.tf
    │
    ├── environments/
    │     └── dev/
    │          ├── main.tf
    │          ├── variables.tf
    │          ├── outputs.tf
    │          └── terraform.tfvars
    │
    └── modules/
          ├── vpc/
          │     ├── main.tf
          │     ├── variables.tf
          │     └── outputs.tf
          │
          ├── eks/
          │     ├── main.tf
          │     ├── variables.tf
          │     └── outputs.tf
          │
          ├── irsa/
          │     ├── main.tf
          │     └── variables.tf
          │
          ├── ebs-csi-driver/
          │     └── main.tf
          │
          └── velero-backup/
                ├── main.tf
                └── variables.tf

```


### Update on the project:

#### Completed items:
 - **terraform** : 
    - modules:
        - VPC - done
        - eks - working on it.





Dex and GitHub OAuth Integration Plan
This plan details the approach for integrating GitHub OAuth into your Kubernetes project and Harbor registry.

Approach Overview
Harbor natively supports OpenID Connect (OIDC) for authentication but does not natively support raw OAuth2 like GitHub provides. To bridge this gap, we will deploy Dex to your cluster. Dex is an identity service that uses OIDC to drive authentication for other apps. It acts as a middleman:

When you click "Login with OIDC" in Harbor, Harbor redirects you to Dex.
Dex redirects you to GitHub for OAuth2 authentication.
GitHub authenticates you and returns a token to Dex.
Dex converts this to a standard OIDC token and sends it back to Harbor.
Harbor logs you in.
User Review Required
IMPORTANT

To configure Dex, you must first create an OAuth application in your GitHub account to get a Client ID and Client Secret.

Steps to create a GitHub OAuth App:

Go to your GitHub profile -> Settings -> Developer Settings -> OAuth Apps.
Click New OAuth App.
Application Name: Harbor Registry Dex (or similar)
Homepage URL: https://harbor.sudheeshbalakrishna.in
Authorization callback URL: https://dex.sudheeshbalakrishna.in/callback
Register the application, generate a new client secret, and save both the Client ID and the Client Secret securely. Provide them to me when you are ready to proceed with the execution.
Proposed Changes
Configuration Files
[NEW] 
dex-values.yaml
We will create a Helm values file for Dex. It will configure:

An NGINX Ingress route for dex.sudheeshbalakrishna.in via cert-manager.
The github connector configuration (requiring your Client ID and Secret).
A staticClients block defining Harbor as an authorized client to consume Dex tokens.
[MODIFY] 
harbor-values.yaml
We will add standard OIDC configuration parameters so Harbor knows to delegate authentication to your new Dex instance:

yaml
auth:
  mode: "oidc_auth"
  oidc:
    name: "Dex"
    endpoint: "https://dex.sudheeshbalakrishna.in"
    client_id: "harbor"
    client_secret: "<a-secure-secret-shared-between-dex-and-harbor>"
    scope: "openid,profile,email,groups"
    verify_cert: "true"
    auto_onboard: "true"
    user_claim: "name"
[MODIFY] 
infra_setup.md
We will add a new section in your deployment documentation indicating how to install the Dex Helm chart before deploying Harbor, and document the necessary DNS CNAME additions for dex.sudheeshbalakrishna.in.

Verification Plan
Manual Verification
After the changes are applied, we will verify by doing the following:

DNS Validation: Ensure a CNAME record exists mapping dex.sudheeshbalakrishna.in to the NGINX Load Balancer.
Dex Health Check: Navigate to https://dex.sudheeshbalakrishna.in/.well-known/openid-configuration in a browser and verify it returns a valid JSON OIDC configuration.
End-to-end Login:
Navigate to https://harbor.sudheeshbalakrishna.in.
You should see a new button: LOGIN VIA OIDC PROVIDER.
Click it, and you should be redirected to a Dex login page with a "Log in with GitHub" option.
Click it, authorize the GitHub app, and it should redirect you successfully back to Harbor as an authenticated user.