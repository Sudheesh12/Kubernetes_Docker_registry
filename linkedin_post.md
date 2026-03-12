# LinkedIn Post Draft

---

## Option 1 — Story-Focused (Recommended)

🚢 I just built a production-grade private Docker registry on Kubernetes — and here's why it matters.

Most teams default to DockerHub or ECR without thinking twice. But what if you want **full control** over your container images, **access control through your GitHub org**, and **vulnerability scanning** baked right in?

Here's what I deployed end-to-end on AWS EKS:

🔧 **The Stack:**
- **Harbor** — Enterprise-grade private OCI image registry (open source)
- **Dex** — OIDC identity provider acting as a GitHub OAuth bridge
- **cert-manager** — Automated Let's Encrypt TLS certificates
- **NGINX Ingress** — Routing + TLS termination backed by an AWS NLB
- **Terraform** — 100% Infrastructure-as-Code for VPC, EKS, IAM, and storage
- **Trivy** — Integrated vulnerability scanning on every image push

🔐 **Authentication flow:**
Developer clicks "Login via GitHub" → Harbor redirects to Dex → Dex authenticates with GitHub OAuth → Dex issues an OIDC token back to Harbor → Developer is logged in.
No additional passwords. No separate user management. Just GitHub SSO.

⚠️ **The trickiest part?** AWS ALBs can't use Kubernetes TLS secrets (they need ACM). Switching to NGINX Ingress + NLB with cert-manager was the key insight that made TLS work cleanly.

The whole thing runs with rolling deployments, HA replicas across Harbor Portal/Core/Registry, and gp3 EBS volumes for persistent storage.

If you're running microservices on Kubernetes, owning your registry is worth the effort.

Happy to discuss the architecture or share the repo — drop a comment! 👇

#Kubernetes #DevOps #AWS #EKS #Docker #Harbor #Terraform #CloudNative #CICD #Containers #OpenSource

---

## Option 2 — Technical / List Format

🔒 Built a self-hosted private Docker registry on AWS EKS with GitHub SSO. Here's the full stack:

✅ **Harbor** for the OCI image registry  
✅ **Dex** as the OIDC identity broker  
✅ **GitHub OAuth** for Single Sign-On (no separate user DB)  
✅ **cert-manager + Let's Encrypt** for automated TLS  
✅ **NGINX Ingress + AWS NLB** for traffic routing  
✅ **Trivy** for automated image vulnerability scanning  
✅ **Terraform** for all AWS infrastructure (VPC, EKS, IAM, EBS CSI)  

Key challenge: AWS ALBs require ACM certificates and can't read Kubernetes Secrets — switching to NGINX Ingress on an NLB unblocked the whole TLS setup.

CLI users authenticate using a Harbor-issued CLI secret after their initial GitHub SSO login — no device flow, no token juggling.

This is especially useful for teams running air-gapped workloads or wanting to avoid DockerHub rate limits and ECR vendor lock-in.

Repo link in comments 👇

#Kubernetes #Docker #AWS #DevOps #EKS #Harbor #Terraform #GitHubOAuth #CloudNative

---

## Option 3 — Humble / Learning-Focused

Just finished a project I've been grinding on: a **self-hosted private Docker registry on Kubernetes**, deployed entirely on AWS EKS. 💪

The goal was simple — own the full registry stack, no third-party SaaS. The reality was a lot of debugging:

❌ ALB couldn't use cert-manager secrets (switched to NGINX Ingress + NLB)  
❌ Dex CrashLoopBackOff because of wrong storage config key in the Helm values  
❌ Docker push failing with 401 Unauthorized (needed to use Harbor CLI secret, not GitHub password)  

All issues I figured out along the way — each one taught me something concrete about how Kubernetes, AWS networking, OAuth, and OIDC actually work under the hood.

Final stack: **Harbor + Dex + GitHub OAuth + cert-manager + NGINX + Terraform.**

The best way to really understand something is to build it and break it a few times. 👨‍💻

#Kubernetes #DevOps #AWS #Docker #Learning #CloudNative #Terraform #EKS

---

## Tips for Posting

- **Best time to post on LinkedIn:** Tuesday–Thursday, 8–10am or 12–1pm in your local timezone.
- **Add a screenshot or diagram** of the Harbor UI or architecture to drastically increase impressions (images get ~3x more reach than text-only posts).
- **Pin your GitHub repo link** in the first comment, not in the post body (LinkedIn suppresses posts with external links).
- **Engage early** — reply to every comment in the first hour to boost the post in the algorithm.
- If you want maximum reach, go with **Option 1** (story format). If you're targeting technical recruiters or engineers, **Option 2** performs well too.
