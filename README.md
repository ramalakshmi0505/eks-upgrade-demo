# eks-upgrade-demo

A small, opinionated demo of how to upgrade an Amazon EKS cluster the boring
way: as a one-line change, reviewed as a pull request, with the plan attached.

Built with Terraform and GitHub Actions. No upgrades from a laptop. No surprises
in the cluster.

## The idea

The Kubernetes version is a single variable:

```hcl
kubernetes_version = "1.32"
```

To upgrade, you bump it in a pull request. GitHub Actions runs `terraform plan`
and posts the diff as a comment, so the whole team sees exactly what will change
before anyone approves. CoreDNS, kube-proxy, the VPC CNI, and the managed node
group all move with the cluster.

```
  PR: kubernetes_version 1.32 -> 1.33
        │
        ▼
  GitHub Actions runs terraform plan  ──►  posts the plan as a PR comment
        │
        ▼  (merge after review)
  terraform apply
        │
        ├─ control plane upgrades first (non-disruptive)
        ├─ add-ons move to compatible versions
        └─ node group rolls to match, one batch at a time
```

## What's here

- `main.tf`, `variables.tf`, `outputs.tf` build the cluster with the
  [terraform-aws-modules/eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
  module (v21), a managed node group, and EKS-managed add-ons.
- `.github/workflows/terraform-plan.yml` runs plan on every pull request and
  comments the diff. It authenticates to AWS with OIDC, so there is no static
  AWS key stored in GitHub.
- `scripts/check-deprecated-apis.sh` scans for Kubernetes APIs removed in the
  target version, before you upgrade.
- `docs/UPGRADE.md` is the step-by-step runbook.

## Stack

- Terraform >= 1.5.7, AWS provider v6
- terraform-aws-modules/eks ~> 21.0
- Kubernetes 1.32 to 1.33 (AL2023 nodes)
- GitHub Actions with AWS OIDC

## Quick start

Prerequisites: an AWS account, an existing VPC with private subnets, Terraform,
and the AWS CLI configured.

```bash
# 1. Set your values
cp terraform.tfvars.example terraform.tfvars
# edit vpc_id and subnet_ids

# 2. Stand up the cluster on 1.32
terraform init
terraform apply

# 3. Point kubectl at it
aws eks update-kubeconfig --name upgrade-demo --region eu-central-1
kubectl get nodes
```

## Run the upgrade

```bash
# 1. Check for deprecated APIs first
./scripts/check-deprecated-apis.sh 1.33

# 2. Bump the version in terraform.tfvars
#    kubernetes_version = "1.33"

# 3. Open a PR. Read the plan comment. Merge.

# 4. Apply
terraform apply
kubectl get nodes -w
```

Full details in [docs/UPGRADE.md](docs/UPGRADE.md).

## CI setup (one time)

The plan workflow uses OIDC, so set:

- Repo secret `AWS_PLAN_ROLE_ARN`: an IAM role that trusts GitHub's OIDC
  provider and has permission to run a plan.
- Repo variable `AWS_REGION`: for example `eu-central-1`.

No access keys in GitHub Secrets.

## Notes and limitations

This is a learning and demo repo, not a production module.

- It expects an existing VPC. Plug in your own `vpc_id` and `subnet_ids`, or add
  the [VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
- It uses a single managed node group for clarity. Real clusters often have
  several, plus Karpenter for scaling.
- EKS control planes cannot be downgraded, which is why the plan review and the
  deprecated-API check happen before the apply.

## License

MIT
