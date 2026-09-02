# AWS Deployment Guide

Complete guide to deploying Poultry Farm Command Center to AWS.

---

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI v2 installed and configured
- Docker installed locally
- GitHub repository with repository secrets configured

---

## Phase 1: AWS Service Setup

### 1.1 Create RDS PostgreSQL Databases

#### Development Instance
```bash
aws rds create-db-instance \
  --db-instance-identifier poultry-dev \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.3 \
  --master-username poultry_admin \
  --master-user-password '<STRONG_PASSWORD>' \
  --allocated-storage 20 \
  --storage-type gp3 \
  --region ap-south-1 \
  --no-publicly-accessible \
  --db-name poultry_dev
```

#### Production Instance
```bash
aws rds create-db-instance \
  --db-instance-identifier poultry-prod \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --engine-version 15.3 \
  --master-username poultry_admin \
  --master-user-password '<STRONG_PASSWORD>' \
  --allocated-storage 100 \
  --storage-type gp3 \
  --region ap-south-1 \
  --no-publicly-accessible \
  --db-name poultry_prod \
  --multi-az \
  --backup-retention-period 30
```

### 1.2 Create ElastiCache Redis

#### Development
```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id poultry-redis-dev \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --region ap-south-1
```

#### Production
```bash
aws elasticache create-replication-group \
  --replication-group-description "Poultry Farm Redis" \
  --replication-group-id poultry-redis-prod \
  --cache-node-type cache.t3.small \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-clusters 2 \
  --automatic-failover-enabled \
  --region ap-south-1
```

### 1.3 Create AWS Cognito User Pool

#### Step 1: Create User Pool
```bash
aws cognito-idp create-user-pool \
  --pool-name PoultryFarmOwners \
  --region ap-south-1 \
  --auto-verified-attributes email \
  --mfa-configuration OPTIONAL \
  --account-recovery-setting PriorityList='[{"Priority":1,"Name":"verified_email"}]'
```

#### Step 2: Create App Client
```bash
aws cognito-idp create-user-pool-client \
  --user-pool-id ap-south-1_XXXXXXXX \
  --client-name PoultryDashboard \
  --region ap-south-1 \
  --callback-urls '["https://app.yourdomain.com/auth/callback"]' \
  --logout-urls '["https://app.yourdomain.com"]' \
  --allowed-o-auth-flows 'code' \
  --allowed-o-auth-scopes 'phone' 'email' 'openid' 'profile' \
  --allowed-o-auth-flows-user-pool-client
```

#### Step 3: Create Admin User
```bash
aws cognito-idp admin-create-user \
  --user-pool-id ap-south-1_XXXXXXXX \
  --username owner@farm.com \
  --message-action SUPPRESS \
  --temporary-password TempPassword123! \
  --region ap-south-1

aws cognito-idp admin-set-user-password \
  --user-pool-id ap-south-1_XXXXXXXX \
  --username owner@farm.com \
  --password FinalPassword123! \
  --permanent \
  --region ap-south-1
```

### 1.4 Create S3 Buckets

#### Development
```bash
aws s3 mb s3://poultry-dashboard-dev \
  --region ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket poultry-dashboard-dev \
  --versioning-configuration Status=Enabled
```

#### Production
```bash
aws s3 mb s3://poultry-dashboard-prod \
  --region ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket poultry-dashboard-prod \
  --versioning-configuration Status=Enabled
```

### 1.5 Create CloudFront Distributions

#### Development
```bash
aws cloudfront create-distribution \
  --distribution-config file://cf-dev-config.json \
  --region ap-south-1
```

`cf-dev-config.json`:
```json
{
  "CallerReference": "dev-$(date +%s)",
  "Aliases": {
    "Quantity": 1,
    "Items": ["dev-app.yourdomain.com"]
  },
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "S3-poultry-dashboard-dev",
      "DomainName": "poultry-dashboard-dev.s3.ap-south-1.amazonaws.com",
      "S3OriginConfig": {}
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-poultry-dashboard-dev",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {"Forward": "none"}
    }
  },
  "Enabled": true
}
```

### 1.6 Create Route 53 Records

```bash
# Get hosted zone ID
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name yourdomain.com \
  --query 'HostedZones[0].Id' \
  --output text)

# Create API record (pointing to ALB)
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://route53-api.json

# Create app record (pointing to CloudFront)
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://route53-app.json
```

### 1.7 Create ECR Repositories

```bash
aws ecr create-repository \
  --repository-name poultry-api \
  --region ap-south-1

aws ecr create-repository \
  --repository-name poultry-intelligence \
  --region ap-south-1
```

### 1.8 Create ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name poultry-command-center \
  --region ap-south-1

# Create capacity providers
aws ecs create-capacity-provider \
  --name FARGATE_SPOT \
  --auto-scaling-group-provider autoScalingGroupArn=arn:aws:autoscaling:ap-south-1:ACCOUNT_ID:autoScalingGroup:name
```

### 1.9 Create IAM Roles

#### Task Execution Role
```bash
aws iam create-role \
  --role-name PoultryECSTaskExecutionRole \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name PoultryECSTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam attach-role-policy \
  --role-name PoultryECSTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
```

#### Task Role
```bash
aws iam create-role \
  --role-name PoultryECSTaskRole \
  --assume-role-policy-document file://trust-policy.json

aws iam put-role-policy \
  --role-name PoultryECSTaskRole \
  --policy-name PoultryECSTaskPolicy \
  --policy-document file://task-policy.json
```

---

## Phase 2: Environment Variables & Secrets

### Store in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
  --name poultry/dev/db-password \
  --secret-string '<DB_PASSWORD>' \
  --region ap-south-1

aws secretsmanager create-secret \
  --name poultry/dev/jwt-secret \
  --secret-string '<JWT_SECRET>' \
  --region ap-south-1

aws secretsmanager create-secret \
  --name poultry/dev/cognito-config \
  --secret-string '{"user_pool_id":"...","client_id":"..."}' \
  --region ap-south-1
```

### GitHub Actions Secrets

Add to repository settings:

```
AWS_ACCOUNT_ID=123456789012
AWS_ROLE_ARN_DEV=arn:aws:iam::123456789012:role/GitHubActionsRole
AWS_ROLE_ARN_PROD=arn:aws:iam::123456789012:role/GitHubActionsRole
```

---

## Phase 3: Database Migrations

### Upload Initial Schema

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier poultry-dev \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Apply schema
psql postgresql://admin:password@$RDS_ENDPOINT:5432/poultry_dev \
  < infra/aws/rds_schema.sql

psql postgresql://admin:password@$RDS_ENDPOINT:5432/poultry_dev \
  < infra/aws/rds_rls_policies.sql

psql postgresql://admin:password@$RDS_ENDPOINT:5432/poultry_dev \
  < infra/aws/rds_indexes.sql
```

### Run Alembic Migrations

```bash
# Connect to RDS
export DATABASE_URL=postgresql://admin:password@$RDS_ENDPOINT:5432/poultry_dev

cd apps/api
alembic upgrade head
```

---

## Phase 4: Docker Build & ECR Push

```bash
# Authenticate with ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-south-1.amazonaws.com

# Build image
docker build -t poultry-api:latest -f Dockerfile .

# Tag for ECR
docker tag poultry-api:latest \
  123456789012.dkr.ecr.ap-south-1.amazonaws.com/poultry-api:latest

# Push
docker push 123456789012.dkr.ecr.ap-south-1.amazonaws.com/poultry-api:latest
```

---

## Phase 5: ECS Task Definitions

### Create Task Definition

```bash
aws ecs register-task-definition \
  --family poultry-api \
  --task-role-arn arn:aws:iam::ACCOUNT_ID:role/PoultryECSTaskRole \
  --execution-role-arn arn:aws:iam::ACCOUNT_ID:role/PoultryECSTaskExecutionRole \
  --network-mode awsvpc \
  --container-definitions file://task-def.json \
  --cpu 256 \
  --memory 512 \
  --region ap-south-1
```

`task-def.json`:
```json
[
  {
    "name": "poultry-api",
    "image": "123456789012.dkr.ecr.ap-south-1.amazonaws.com/poultry-api:latest",
    "portMappings": [
      {
        "containerPort": 8000,
        "hostPort": 8000,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "ENVIRONMENT",
        "value": "development"
      }
    ],
    "secrets": [
      {
        "name": "DATABASE_URL",
        "valueFrom": "arn:aws:secretsmanager:ap-south-1:ACCOUNT_ID:secret:poultry/dev/db-url"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/poultry-api",
        "awslogs-region": "ap-south-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
```

---

## Phase 6: ECS Services

```bash
# Create service
aws ecs create-service \
  --cluster poultry-command-center \
  --service-name poultry-api-dev \
  --task-definition poultry-api:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=DISABLED}" \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:ap-south-1:ACCOUNT_ID:targetgroup/poultry-api/xxx,containerName=poultry-api,containerPort=8000 \
  --region ap-south-1
```

---

## Monitoring & Logging

### CloudWatch Logs

```bash
# Create log group
aws logs create-log-group \
  --log-group-name /ecs/poultry-api \
  --region ap-south-1

# View logs
aws logs tail /ecs/poultry-api --follow
```

### CloudWatch Alarms

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name poultry-api-high-cpu \
  --alarm-description "Alert if CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:ap-south-1:ACCOUNT_ID:alert-topic
```

---

## Scaling

### Auto Scaling Policy

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/poultry-command-center/poultry-api-dev \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 \
  --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --policy-name cpu-scaling \
  --service-namespace ecs \
  --resource-id service/poultry-command-center/poultry-api-dev \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

---

## CI/CD Pipeline

### GitHub Actions

See `.github/workflows/deploy-*.yml` for automated deployments.

**Trigger:** Push to `dev` branch → Deploy to dev ECS
**Trigger:** Merge to `main` branch → Deploy to prod ECS

---

## Rollback

```bash
# Revert to previous task definition
aws ecs update-service \
  --cluster poultry-command-center \
  --service poultry-api-dev \
  --task-definition poultry-api:PREVIOUS_REVISION

# Force update
aws ecs update-service \
  --cluster poultry-command-center \
  --service poultry-api-dev \
  --force-new-deployment
```

---

## Cost Optimization

- Use **Fargate Spot** for non-critical tasks (up to 70% savings)
- Set **RDS backup retention** to 7 days (not 30)
- Use **ElastiCache** only for prod (disable for dev)
- Set **ECS desired count** to 1 for dev, 2 for prod

---

## Support

- AWS Documentation: https://docs.aws.amazon.com
- Troubleshooting: See logs in CloudWatch
- Alerts: Monitor SNS topics for anomalies
