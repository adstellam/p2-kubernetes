!/bin/bash

##
## The AWS CLI config and credentials
##
ACCOUNT=123331079503
AWS_ACCESS_KEY_ID=AKIARZNY25VH2GIWZGPK
AWS_SECRET_ACCESS_KEY=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
AWS_REGION=us-west-1

##
## To set up ~./aws/config and ~/.aws/credentials, which are used by aws-cli
##
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile stout
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile stout
aws configure set region AWS_REGION --profile stout
