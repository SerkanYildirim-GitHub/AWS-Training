#!/usr/bin/env bash
# Read-only post-deletion check. Not a claim this script was run during the original exercise.
set -euo pipefail
STACK="CFN-Regional-Web"
for REGION in us-east-1 eu-west-3 ap-southeast-1; do
  echo "===== $REGION ====="
  echo 'Active stack-tagged instances:'
  aws ec2 describe-instances --region "$REGION" \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK" \
      "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" \
    --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output table
  echo 'Stack-tagged security groups:'
  aws ec2 describe-security-groups --region "$REGION" \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK" \
    --query 'SecurityGroups[].[GroupId,GroupName]' --output table
  echo 'Stack status (empty means no active stack):'
  aws cloudformation list-stacks --region "$REGION" \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[?StackName==`CFN-Regional-Web`].[StackName,StackStatus]' --output table
done
