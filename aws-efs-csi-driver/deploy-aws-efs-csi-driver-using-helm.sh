#!/bin/bash

##
## To create AmazonEKS_EFS_CSI_Driver_Policy
##
aws iam create-policy \
--policy-name AmazonEKS_EFS_CSI_Driver_Policy \
--policy-document file://aws-efs-csi-driver-iam-policy.json 

##
## To create AmazonEKS_EFS_CSI_Driver_Role
##
aws iam create-role \
--role-name AmazonEKS_EFS_CSI_Driver_Role \
--assume-role-policy-document file://aws-efs-csi-driver-role-trust-policy.json 

aws iam attach-role-policy \
--role-name AmazonEKS_EFS_CSI_Driver_Role \
--policy-arn arn:aws:iam::123331079503:policy/AmazonEKS_EFS_CSI_Driver_Policy 

##
## To deploy a service account for aws-efs-cs-driver
##
kubectl apply -f aws-efs-csi-driver-sa.yaml 

##
## To deploy aws-efs-csi-driver using kubectl
##
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.3"

##
## Alternatively, aws-efs-csi-driver can be deployed using helm chart
##
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
-n kube-system \
--set controller.serviceAccount.create=false \
--set controller.serviceAccount.name=efs-csi-controller-sa \
--set region=us-west-1 \
--set vpcId=vpc-04df3bca74ea1a4b7 \
--set image.repository=602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-efs-csi-driver:master:v1.4.0