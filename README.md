# Cloud-Native Image Moderation Pipeline

## Overview

A serverless image moderation pipeline built using AWS services.

Images uploaded to Amazon S3 are processed asynchronously through Amazon SQS and AWS Lambda. Amazon Rekognition analyzes the image for moderation labels. Results are stored in DynamoDB and flagged images generate SNS notifications.

## Architecture

S3
↓
SQS
↓
Lambda
↓
Rekognition
↓
DynamoDB
↓
SNS
↓
Email

Failed messages are retried and eventually moved to a Dead Letter Queue.

CloudWatch provides monitoring and alarms.

CloudTrail provides AWS API auditing.

GitHub Actions provides CI/CD.

GitHub authenticates with AWS using OIDC instead of long-lived access keys.

## AWS Services

- Amazon S3
- Amazon SQS
- AWS Lambda
- Amazon Rekognition
- Amazon DynamoDB
- Amazon SNS
- Amazon CloudWatch
- AWS CloudTrail
- AWS IAM

## Security

- S3 public access blocked
- S3 server-side encryption enabled
- Least-privilege IAM
- Lambda execution role
- GitHub OIDC authentication
- No hard-coded AWS credentials
- CloudTrail auditing

## Reliability

- SQS buffering
- Automatic retries
- Dead Letter Queue
- Lambda reserved concurrency
- Idempotent processing
- CloudWatch alarms

## CI/CD

Pull requests run:

1. Python validation
2. Lambda packaging

Merges to main:

1. Authenticate through GitHub OIDC
2. Package Lambda
3. Deploy Lambda automatically

## Data Flow

1. User uploads image to S3.
2. S3 generates ObjectCreated event.
3. S3 sends event to SQS.
4. Lambda consumes SQS message.
5. Lambda calls Rekognition.
6. Moderation result is stored in DynamoDB.
7. Flagged images trigger SNS.
8. SNS sends email notification.
9. Failed processing is retried.
10. Repeated failures move to DLQ.

## Monitoring

CloudWatch monitors:

- Lambda errors
- Lambda duration
- Lambda throttling
- SQS backlog
- DLQ messages

## Project Structure

```text
image-moderation-project/
├── lambda/
│   └── lambda_function.py
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
├── .gitignore
└── README.md
