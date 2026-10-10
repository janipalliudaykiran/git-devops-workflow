# Git DevOps Workflow

Learning Git as part of my AWS DevOps journey.

## Learning Goals

- Git fundamentals
- Branching and collaboration
- Docker
- Kubernetes
- AWS
- CI/CD
- Infrastructure automation



## Docker CI/CD with GitHub Actions and Amazon ECR

### Project overview

This project demonstrates an automated CI pipeline for a Python application and the publishing of a validated Docker image to Amazon Elastic Container Registry (ECR).

The pipeline uses GitHub Actions, AWS IAM OpenID Connect (OIDC), and a private ECR repository.

### Architecture

Developer opens a pull request
→ GitHub Actions runs Python tests
→ Docker image is built
→ Hardened-container smoke test runs
→ Pull request is merged into main
→ GitHub Actions obtains temporary AWS credentials through OIDC
→ Tested image is transferred between jobs
→ Image is pushed to private Amazon ECR
→ Image is pulled and tested locally

### Technologies used

- Git and GitHub pull requests
- GitHub Actions and workflow YAML
- Python 3.13 and pytest
- Docker and Dockerfile hardening
- Amazon ECR
- AWS IAM and GitHub Actions OIDC
- GitHub Actions artifacts

### CI workflow

For pull requests targeting `main`, the workflow:

1. Checks out the repository.
2. Sets up Python and installs test dependencies.
3. Runs the Python tests.
4. Builds the Docker image.
5. Runs a smoke test with a read-only root filesystem, all Linux capabilities dropped, and `no-new-privileges`.
6. Verifies the expected application output and the configured non-root user.

### Publishing to Amazon ECR

After a successful push to `main`, the workflow:

1. Saves the tested Docker image and transfers it as a workflow artifact.
2. Requests temporary AWS credentials through GitHub OIDC.
3. Authenticates to Amazon ECR.
4. Tags and pushes the tested image to the private ECR repository.

The image tag contains the Git commit SHA and workflow run attempt, making the published artifact traceable to its source revision.

### Security practices demonstrated

- Runs the application as a non-root user.
- Uses a read-only container root filesystem for the smoke test.
- Drops Linux capabilities and disables privilege escalation.
- Uses GitHub OIDC instead of storing long-lived AWS access keys.
- Restricts AWS role trust to the intended GitHub repository and `main` branch.
- Limits ECR push permissions to the intended repository.
- Uses `.dockerignore` to exclude unnecessary files from the Docker build context.

### Verification

The pipeline successfully ran Python tests, built the Docker image, and passed the hardened-container smoke test.

The image was successfully published to Amazon ECR, pulled into a local Docker environment, and executed with the expected output:

`Hello from my DevOps application!`

The pulled image was also verified to run as `appuser`.

### Current scope and future improvements

This is a hands-on learning and portfolio project. It currently packages and publishes a sample Python application; it does not deploy the application to a production runtime.

Potential next improvements include image vulnerability scanning, deployment automation, monitoring, and runtime health checks where appropriate.

