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



