# Kubernetes_Docker_registry

## File Structure:

```
cncf-registry-project/
│
├── terraform/
│   ├── backend/
│   │     └── s3-backend.tf
│   │
│   ├── environments/
│   │     └── dev/
│   │          ├── main.tf
│   │          ├── variables.tf
│   │          ├── outputs.tf
│   │          └── terraform.tfvars
│   │
│   └── modules/
│         ├── vpc/
│         ├── eks/
│         ├── irsa/
│         ├── ebs-csi-driver/
│         └── velero-backup/
│
└── kubernetes/
    ├── namespace/
    ├── storage-class/
    ├── registry/
    ├── dex/
    ├── trivy/
    └── network-policy/

```


### Update on the project:

#### Completed items:
 - **terraform** : 
    - modules:
        - VPC - done
        -



