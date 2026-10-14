
# ECS Deployment Monitoring and Incident Runbook

## Project overview

This hands-on project demonstrates a CI/CD pipeline for a Python HTTP
application using GitHub Actions, Docker, Amazon ECR, AWS IAM OIDC,
Amazon ECS Fargate, CloudWatch Logs, EventBridge and SNS.

## Architecture

1. GitHub Actions runs Python tests and builds the Docker image.
2. The pipeline validates the container and publishes the tested image to ECR.
3. GitHub OIDC provides temporary AWS credentials to the permitted workflow.
4. ECS uses a task definition to run the image on Fargate.
5. CloudWatch Logs stores application output.
6. EventBridge matches ECS deployment-failure events.
7. SNS sends an email notification to a confirmed subscription.

## Monitoring components

- CloudWatch Logs: application output and HTTP request records.
- ECS service events: scheduling, image-pull and deployment messages.
- ECS deployment circuit breaker: detects failed deployments and can
  roll back to the last successfully completed deployment.
- EventBridge: matches SERVICE_DEPLOYMENT_FAILED events for the target service.
- SNS: delivers notifications to the subscribed email endpoint.

## Incident example: missing container image

### Symptom

An ECS deployment failed while attempting to retrieve a container image.

### Evidence

ECS service events reported CannotPullContainerError because the
referenced image tag did not exist in the private ECR repository.

### Recovery

1. Inspect ECS service events and the failed task's reason.
2. Identify the task-definition revision and image tag involved.
3. Confirm the previous deployment completed successfully.
4. Allow the ECS deployment circuit breaker to roll back.
5. Confirm the previous revision is running and the deployment is stable.
6. Test the application's root and health endpoints.
7. Clean up temporary lab resources.

### Verified lab result

A deliberately invalid image tag caused deployment revision 3 to fail
after repeated image-pull attempts. ECS initiated rollback to revision 2,
which was the last completed deployment.

The application was previously verified to return HTTP 200 from both
the root endpoint and /health.

## Alert validation status

- SNS email subscription: confirmed.
- SNS-to-email delivery: verified with a test message.
- EventBridge rule configured for ECS deployment failures.
- End-to-end delivery of an actual ECS deployment-failure event:
  not yet verified after configuring the rule.

The next controlled deployment lab should verify the full
ECS event -> EventBridge -> SNS -> email path.

## Security and cost controls

- Use least-privilege IAM roles.
- Use GitHub OIDC rather than storing long-lived AWS access keys.
- Restrict application access with the security group's intended source CIDR.
- Keep automatic ECS deployment disabled when the lab is not in use.
- Stop or delete running Fargate services after experiments.
- Review ECR storage and CloudWatch log retention for ongoing charges.

## Lessons learned

- A running container can still be unreachable because of network rules.
- A healthy container does not prove public connectivity.
- Task-definition revisions identify deployment configurations.
- ECS events, task reasons and application logs provide different evidence.
- Rollback should be verified by checking deployment state and application behaviour.


## CPU monitoring and alert validation

### Configuration

- CloudWatch namespace: AWS/ECS
- Metrics observed: CPUUtilization and MemoryUtilization
- Alarm: devops-ecs-cpu-high
- Intended CPU threshold: 80%
- Intended evaluation: 3 of 5 one-minute periods
- Notification destination: SNS topic devops-ecs-alerts

### Validation result

A bounded HTTP load test increased the observed ECS CPU utilization
to approximately 75% before it decreased.

The alarm was temporarily configured with a lower threshold for
validation. It entered ALARM state and an SNS email was received.

After testing, the ECS metrics-lab service was deleted.

The alarm should be restored to its intended 80% threshold,
3-of-5-period evaluation and missing-data treatment of missing.

### Remaining validation

SNS email delivery was verified. Actual ECS deployment-failure
event delivery through EventBridge to SNS remains to be verified
with a future controlled deployment test.

