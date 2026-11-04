# ECS Deployment Failure Runbook

## Architecture

ECS -> EventBridge -> SNS -> Email

## Normal deployment verification

1. Check ECS service status.
2. Verify desired and running task counts.
3. Check task health.
4. Test the application health endpoint.
5. Inspect CloudWatch logs.

## Deployment failure investigation

1. Inspect ECS service events.
2. Check the stopped task reason.
3. Identify whether the image pull failed,
   the container crashed, or health checks failed.
4. Check the EventBridge rule and target.
5. Check the SNS topic policy.
6. Verify the email subscription.

## Recovery

1. Confirm ECS circuit-breaker rollback.
2. Check the previous completed deployment.
3. Restore the known-good image configuration.
4. Run terraform plan.
5. Apply the corrected configuration.
6. Verify the application health endpoint.

## Safety

- Never commit Terraform state.
- Never intentionally leave the broken image configuration.
- Review Terraform plans before applying.
- Check ECS service stability after recovery.
- Destroy lab resources when testing is complete.
