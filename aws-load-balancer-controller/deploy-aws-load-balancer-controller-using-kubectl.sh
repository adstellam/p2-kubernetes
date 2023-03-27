#!/bin/bash

##
## 1. To create AmazonEKSLoadBalancerControllerRole
##
AWS_LOAD_BALNCER_CONTROLLER_IAM_POLICY =$(aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://aws-load-balancer-controller-iam-policy.json \
--query Policy.Arn
--output text) 

aws iam create-role \
--role-name AmazonEKSLoadBalancerControllerRole \
--assume-role-policy-document file://aws-load-balancer-controller-role-trust-policy.json

aws iam attach-role-policy \
--policy-arn arn:aws:iam:123331079503::policy/AWSLoadBalancerControllerIAMPolicy \
--role-name AmazonEKSLoadBalancerControllerRole

##
## 2. To create AWS IAM service account for aws-load-balancer-controller
##
kubectl apply -f aws-load-balancer-controller-serviceaccount.yaml

#
# 3. To install cert-manager. 
#
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml

##
## 4. To create aws-load-balancer-controller from manifest 
##
kubectl apply -f kube_deploy_v2_4_1.yaml

##
## 5. To verify that the controller is deployed
##
kubectl get deployment -n kube-system aws-load-balancer-controller