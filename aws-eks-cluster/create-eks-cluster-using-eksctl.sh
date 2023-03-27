#!/bin/bash

##
## To create EKS cluster.
##
eksctl create cluster --name stoutEksCluster --region us-west-1 --fargate

##
## To confirm that the stoutEksCluster has been created
##
aws eks describe-cluster --name stoutEksCluster

##
## To associate the IAM-OIDC provider
##
eksctl utils associate-iam-oidc-provider \
—-cluster stoutEksCluster \
—-approve

##
## To create a Fargate profile, which determines what pods are to use the Fargate
##
aws eks create-fargate-profile \
—-fargate-profile-name fp-default \
—-cluster-name stoutEksCluster \
—-pod-execution-role-arn arn:aws:iam::${ACCOUNT}:role/eksFargatePodExecutionRole \
—-selectors '[{"namespace": "default"}, {"namespace": "kube-system"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-api \
--cluster-name stoutEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-stoutEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"api"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-nifi \
--cluster-name stoutEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-stoutEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"nifi"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-postgres \
--cluster-name stoutEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-stoutEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"postgres"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-gitlab \
--cluster-name stoutEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-stoutEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"gitlab"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-api \
--cluster-name stoutEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-stoutEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"api"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

##
## To create a config file in the ~/.kube directory
##
awk eks update-kubeconfig --name stoutEksCluster

