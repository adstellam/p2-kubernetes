#!/bin/bash

##
## To create AWSLoadBalancerControllerIAMPolicy
##
AWS_LOAD_BALNCER_CONTROLLER_IAM_POLICY =$(aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://aws-load-balancer-controller-iam-policy.json \
--query Policy.Arn
--output text) 

##
## To create AmazonEKSLoadBalancerControllerRole and AWS IAM service account for aws-load-balancer-controller
##
eksctl create iamserviceaccount \
--cluster=stoutEksCluster \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--role-name AmazonEKSLoadBalancerControllerRole \
--attach-policy-arn=arn:aws:iam::123331079503:policy/AWSLoadBalancerControllerIAMPolicy \
--approve
# arn:aws:iam::123331079503:policy/AWSLoadBalancerControllerIAMPolicy

##
## To deploy aws-load-balancer-controller using helm chart
##
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=stoutEksCluster \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
--set region=us-west-1 \
--set vpcId=vpc-04df3bca74ea1a4b7 \
--set image.repository=602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-load-balancer-controller

##
## To verify that the controller is deployed
##
kubectl get deployment -n kube-system aws-load-balancer-controller
