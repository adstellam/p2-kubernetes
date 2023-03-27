#!/bin/bash

##
## To create the service role to be assumed by eks.amazonaws.com
##
aws iam create-role —-role-name eksClusterRole —-assume-role-policy-document file://eks-cluster-role-trust-policy.json 
aws iam attach-role-policy —-role-name eksClusterRole —-policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
# EKS_CLUSTER_ROLE=arn:aws:iam::123331079503:role/eksClusterRole 

##
## To create the service role to be assumed by eks-fargate-pods.amazonaws.com 
##
aws iam create-role —-role-name eksFargatePodExecutionRole —-assume-role-policy-document file://eks-fargate-pod-execution-role-trust-policy.json \
aws iam attach-role-policy —-role-name eksFargatePodExecutionRole —-policy-arn arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy
# EKS_FARGATE_POD_EXECUTION_ROLE=arn:aws:iam::123331079503:role/eksFargatePodExecutionRole

##
## To request a TLS certificate 
##
aws acm request-certificate \
--domain-name app.stoutagtech.dev \
--validation-method DNS 

##
## To generate a secret key to be used for encryption in the K8s cluster [Write down the generated key and use it when creating the cluster.]
##
K8S_SECRET_KEY_ARN=$(aws kms create-key \
--query KeyMetadata.Arn \
—-output text)
#K8S_SECRET_KEY_ID=63cd44a8-6376-4e7b-8f0b-4ccde1247981
#K8S_SECRET_KEY_ARN=arn:aws:kms:us-west-1:123331079503:key/63cd44a8-6376-4e7b-8f0b-4ccde1247981

##
## To create a VPC for the K8s cluster and then create a private subnet and a public subnet withing the VPC
##
VPC_ID=$(aws ec2 create-vpc \
--cidr-block 192.168.0.0/16 \
--query Vpc.VpcId \
--output text)
# VPC_ID=

##
## To set the enable-dns-hostnames attribute of the VPC to true
##
aws ec2 modify-vpc-attribute \
--vpc-id $VPC_ID \
--enable-dns-hostnames

##
## To create subnets: a private subnet and two public subnets with one public subnet for each AZ
##
SUBNET_PVT_1_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block 192.168.21.0/24 \
--availability-zone us-west-1b \
--query Subnet.SubnetId \
--output text)
# PRIVATE_SUBNET_AZ1B_ID=

SUBNET_PUB_1_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block 192.168.22.0/24 \
--availability-zone us-west-1b \
--query Subnet.SubnetId \
--output text)
# PUBLIC_SUBNET_AZ1B_ID=

SUBNET_PVT_2_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block 192.168.31.0/24 \
--availability-zone us-west-1c \
--query Subnet.SubnetId \
--output text)
# PRIVATE_SUBNET_AZ1C_ID=

SUBNET_PUB_2_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block 192.168.32.0/24 \
--availability-zone us-west-1c \
--query Subnet.SubnetId \
--output text)
# PUBLIC_SUBNET_AZ1C_ID=

aws ec2 modify-subnet-attribute \
--subnet-id $SUBNET_PUB_1_ID \
--map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
--subnet-id $SUBNET_PUB_2_ID \
--map-public-ip-on-launch

##
## To attach internet gateway to the VPC
##
IGW_ID=$(aws ec2 create-internet-gateway \
--query InternetGateway.InternetGatewayID \
--output text)
# IGW_ID=

aws ec2 attach-internet-gateway \
--vpc-id $VPC_ID \
--internet-gateway-id $IGW_ID 

##
## To create a non-default route table for the VPC and associate the route table with the public subnet created above
##
RT_ID=$(aws ec2 create-route-table \
--vpc-id $VPC_ID \
--query RouteTable.RouteTableId \
--output text)
# RT_ID=

aws ec2 create-route \
--route-table-id $RT_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $IGW_ID

aws ec2 associate-route-table \
--subnet-id $SUBNET_PUB_1_ID \
--route-table-id $RT_ID

aws ec2 associate-route-table \
--subnet-id $SUBNET_PUB_2_ID \
--route-table-id $RT_ID

##
## Add tags to subnets so that EKS can discover them as pod deployment targets [Not necessary for vers 1.19+]
##
#aws ec2 create-tags \
#--resources $SUBNET_PVT_1_ID \
#--tags Key=kubernetes.io/cluster/devEksCluster,Value=shared Key=kubernetes.io/role/internal-elb,Value=1

#aws ec2 create-tags \
#--resources $SUBNET_PUB_1_ID \
#--tags Key=kubernetes.io/cluster/devEksCluster,Value=shared Key=kubernetes.io/role/elb,Value=1

#aws ec2 create-tags \
#--resources $SUBNET_PUB_2_ID \
#--tags Key=kubernetes.io/cluster/devEksCluster,Value=shared Key=kubernetes.io/role/elb,Value==1

##
## To create a K8s cluster
##
aws eks create-cluster \
—-name devEksCluster \
—-kubernetes-version 1.21 \
--role-arn arn:aws:iam::${ACCOUNT}:role/eksClusterRole
—-resources-vpc-config '{"subnetIds":["${SUBNET_PUB_1_ID}","${SUBNET_PUB_2_ID}"],"securityGroupIds":["${SG_ID}"],"endpointPrivateAccess":false,"endpointPublicAccess":true}' \
—-encryption-config '[{"resources":["secrets"],"provider":{"keyArn":"${K8S_SECRET_KEY_ARN}”}}]'
—-logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'

#aws eks create-cluster --profile stout —-name devEksCluster —-kubernetes-version 1.21 --role-arn arn:aws:iam::123331079503:role/eksClusterRole 
# —-resources-vpc-config '{"subnetIds":[],"securityGroupIds":[],"endpointPrivateAccess":false,"endpointPublicAccess":true}'
# —-encryption-config '[{"resources":["secrets"],"provider":{"keyArn":"arn:aws:kms:us-west-1:123331079503:key/63cd44a8-6376-4e7b-8f0b-4ccde1247981”}}]'
# —-logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'

##
## To confirm that the devEksCluster has been created with the right configurations 
##
aws eks describe-cluster \
--name devEksCluster \
--query eks.resourcesVpcConfig

##
## To make sure an OIDC provider has beem created for federation with the devEksCluster
##
aws iam list-open-id-connect-providers
## if it has not beem created yet, create one using either of the following commands 
#eksctl utils associate-iam-oidc-provider \
#—-cluster devEksCluster \
#—-approve
## or 
##aws iam create-open-id-connect-provider \
##--url \
##--thumbprint-list \
##--client-id-list

##
## To create a Fargate profile, which determines what pods are to use the Fargate
##
aws eks create-fargate-profile \
—-fargate-profile-name fp-default \
—-cluster-name devEksCluster \
—-pod-execution-role-arn arn:aws:iam::${ACCOUNT}:role/eksFargatePodExecutionRole \
—-selectors '[{"namespace": "default"}, {"namespace": "kube-system"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-api \
--cluster-name devEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-devEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"api"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-nifi \
--cluster-name devEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-devEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"nifi"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-postgres \
--cluster-name devEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-devEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"postgres"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-gitlab \
--cluster-name devEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-devEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"gitlab"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

aws eks create-fargate-profile \
--fargate-profile-name fp-api \
--cluster-name devEksCluster  \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksctl-devEksCluster-clust-FargatePodExecutionRole-1QEK6CLEVXPM3 \
--selectors '[{"namespace":"api"}]' \
—-subnets $SUBNET_PVT_1_ID $SUBNET_PVT_2_ID 

##
## To create a config file in the ~/.kube directory, which is needed for connection to devEksCluster using kubectl
##
awk eks update-kubeconfig \
--name devEksCluster
