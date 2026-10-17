# Terraform Remote State Design

## Objective

Document how the project can safely share Terraform state
between engineers and CI pipelines.

## Local state limitations

- State is stored on an individual machine.
- Team members may have different copies of state.
- Sharing or committing state creates security and consistency risks.

## Proposed architecture

- Amazon S3 stores Terraform state.
- S3 native lock-file support coordinates write operations.
- S3 versioning supports recovery from accidental changes.
- Encryption and Block Public Access protect stored state.
- IAM permissions restrict access to the state and lock objects.

## Planned backend settings

- Region: ap-south-1
- State key: devops-codex/terraform/terraform.tfstate
- Locking: S3 native lock file
- Encryption: enabled

## Operational safeguards

- Keep Terraform state out of Git.
- Review terraform plan before applying changes.
- Do not disable locking to bypass a lock error.
- Investigate failed operations before attempting recovery.
- Verify the AWS account and backend before migration.
