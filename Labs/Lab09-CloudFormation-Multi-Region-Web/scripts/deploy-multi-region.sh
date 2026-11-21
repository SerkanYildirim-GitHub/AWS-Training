#!/usr/bin/env bash
# Reusable one-command, three-Region deployment using the validated regional template.
# Usage: bash scripts/deploy-multi-region.sh [cloudformation-regional-web.yaml]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="${1:-$LAB_DIR/cloudformation-regional-web.yaml}"
STACK_NAME="CFN-Regional-Web"
REGIONS=(us-east-1 eu-west-3 ap-southeast-1)

if [[ ! -f "$TEMPLATE" ]]; then
  printf 'Template not found: %s\n' "$TEMPLATE" >&2
  exit 1
fi

for REGION in "${REGIONS[@]}"; do
  echo "========================================"
  echo "Deploying CloudFormation in $REGION"
  echo "========================================"

  VPC=$(aws ec2 describe-vpcs \
    --region "$REGION" \
    --filters "Name=is-default,Values=true" \
    --query 'Vpcs[0].VpcId' --output text)
  if [[ -z "$VPC" || "$VPC" == "None" ]]; then
    echo "ERROR: No default VPC in $REGION" >&2
    exit 1
  fi

  SUBNET=$(aws ec2 describe-subnets \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC" "Name=default-for-az,Values=true" \
    --query 'Subnets[0].SubnetId' --output text)
  if [[ -z "$SUBNET" || "$SUBNET" == "None" ]]; then
    echo "ERROR: No default subnet in $REGION" >&2
    exit 1
  fi

  echo "VPC: $VPC"
  echo "Subnet: $SUBNET"
  aws cloudformation deploy \
    --region "$REGION" \
    --template-file "$TEMPLATE" \
    --stack-name "$STACK_NAME" \
    --parameter-overrides "VpcId=$VPC" "SubnetId=$SUBNET" \
    --tags Project=CloudFormation-Multi-Region-Web

  aws cloudformation describe-stacks \
    --region "$REGION" --stack-name "$STACK_NAME" \
    --query 'Stacks[0].{Status:StackStatus,Outputs:Outputs}' --output json
done

echo 'All requested CloudFormation deployments finished successfully.'
