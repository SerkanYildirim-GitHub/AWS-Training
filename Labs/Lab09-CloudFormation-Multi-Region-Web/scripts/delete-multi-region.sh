#!/usr/bin/env bash
# DESTRUCTIVE: deletes only CFN-Regional-Web stacks in the three listed Regions.
# Usage: bash scripts/delete-multi-region.sh
set -euo pipefail

STACK="CFN-Regional-Web"
REGIONS=(us-east-1 eu-west-3 ap-southeast-1)

echo '=== CLOUDFORMATION AUTOMATED CLEANUP ==='
for REGION in "${REGIONS[@]}"; do
  echo "Deleting $STACK in $REGION ..."
  aws cloudformation delete-stack --region "$REGION" --stack-name "$STACK"
  echo "Deletion requested: $REGION"
done

for REGION in "${REGIONS[@]}"; do
  echo "Checking deletion in $REGION ..."
  aws cloudformation wait stack-delete-complete \
    --region "$REGION" --stack-name "$STACK"
  echo "DELETE_COMPLETE: $REGION"
done

echo 'ALL THREE REGIONAL STACKS DELETED'
