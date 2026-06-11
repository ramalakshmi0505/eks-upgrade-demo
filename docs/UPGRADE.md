# EKS Upgrade Runbook

EKS upgrades are routine when they are boring. The aim of this repo is to make
an upgrade a small, reviewed pull request instead of a tense afternoon in the
console.

## The rules

1. One minor version at a time. Go 1.32 to 1.33, not 1.31 to 1.33. EKS does not
   support skipping minor versions.
2. Control plane first, then the nodes. Never both blind at once.
3. Check deprecated APIs before you touch anything.
4. Every change is a pull request with a plan attached.

## Step by step

### 1. Check for deprecated APIs

A new Kubernetes version removes APIs that older manifests may still use. Find
them first.

```bash
./scripts/check-deprecated-apis.sh 1.33
```

Fix anything flagged. This is the step most teams skip and most regret.

### 2. Open the upgrade as a pull request

Bump one variable in `terraform.tfvars` (or `variables.tf`):

```hcl
kubernetes_version = "1.33"   # was 1.32
```

Open a pull request. The `terraform-plan` workflow runs `terraform plan` and
posts the diff as a comment. The plan should show the control plane version
changing. Read it before approving.

### 3. Apply the control plane upgrade

After merge, apply:

```bash
terraform apply
```

The EKS control plane upgrades first. This is non-disruptive to running pods.
EKS managed add-ons (CoreDNS, kube-proxy, VPC CNI, Pod Identity agent) move to
versions compatible with the new Kubernetes version as part of the same apply.

### 4. Roll the node groups

Managed node groups follow the cluster version. The same apply rolls the nodes
to match, replacing them gradually so workloads keep running. Watch the rollout:

```bash
kubectl get nodes -w
```

Nodes drain and replace one batch at a time. Pods reschedule onto the new nodes.

### 5. Verify

```bash
kubectl version
kubectl get nodes        # all nodes on the new version
kubectl get pods -A      # everything healthy
```

## If something goes wrong

You cannot downgrade an EKS control plane. That is exactly why the plan review
and the deprecated-API check happen before the apply, not after. If a node
group rollout misbehaves, you can pause it and investigate while the old nodes
keep serving traffic. Keep the change small so the blast radius stays small.

## Why this layout

- The version is one variable, so an upgrade is a one-line diff anyone can read.
- `terraform plan` on the pull request makes the change visible before it lands.
- The deprecated-API scan catches the breakage that version notes warn about.
- Nothing happens from a laptop against production without a reviewed plan.
