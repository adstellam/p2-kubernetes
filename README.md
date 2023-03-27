#
# To launch an EKS cluster using AWS CLI. The cluster name herein is
# devEksCluster, which you may change to your choice.
#
cd aws-eks &&
./configure-aws-cli.sh &&
./create-eks-cluster-using-aws-cli.sh

#
# Alternatively, an EKS cluster can be launched using eksctl. The cluster name 
# herein is stoutEksCluster, which you may change to your choice.
#
cd aws-eks &&
./configure-aws-cli.sh &&
./create-eks-cluster-using-aws-eksctl.sh

##
## Verify that the EKS cluster has been lauched.
##
aws eks describe-cluster --name <cluster-name>

##
## To create AWS fargate profiles
##
aws eks create-fargate-profile \
--fargate-profile-name fp-dev \
--cluster-name stoutEksCluster \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksFargatePodExecutionRole \
--subnets subnet-06b3140070503319d subnet-02e68b37ed6c787a8 \
--selectors namespace=dev

aws eks create-fargate-profile \
--fargate-profile-name fp-production \
--cluster-name stoutEksCluster \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksFargatePodExecutionRole \
--subnets subnet-06b3140070503319d subnet-02e68b37ed6c787a8 \
--selectors namespace=production

aws eks create-fargate-profile \
--fargate-profile-name fp-postgres \
--cluster-name stoutEksCluster \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksFargatePodExecutionRole \
--subnets subnet-06b3140070503319d subnet-02e68b37ed6c787a8 \
--selectors namespace=postgres

aws eks create-fargate-profile \
--fargate-profile-name fp-gitlab \
--cluster-name stoutEksCluster \
--pod-execution-role-arn arn:aws:iam::123331079503:role/eksFargatePodExecutionRole \
--subnets subnet-06b3140070503319d subnet-02e68b37ed6c787a8 \
--selectors namespace=gitlab

##
##
##
## In next steps, you shall deploy AWS Load Balancer Controller and Ingress 
## Nginx Controller. They are the two of many different types of Kubernetes 
## Ingress Controller which manages the provisioning of AWS ALB/NLB and Nginx,
## respectively, when ingress resource is registered in the Kubernetes api-server. 
## Both will be deployed in the kube-system namespace.
##
##
##

##
## To deploy AWS Load Balancer Controller using kubectl
## 
cd .. &&
cd aws-load-balancer-controller &&
./deploy-aws-load-balancer-controller-using-kubectl.sh

##
## Alternatively, AWS Load Balancer Controller can be deployed using helm
## 
cd .. &&
cd aws-load-balancer-controller &&
./deploy-aws-load-balancer-controller-using-helm.sh

##
## To deploy Ingress Nginx Controller
## 
cd .. &&
cd ingress-nginx-controller &&
./deploy-ingress-nginx-controller-using-kubectl.sh


##
##
##
## Next steps are to make EFS available to the Kubernetes cluster.
##
##
##

##
## To deploy AWS EFS CSI Driver
##
cd .. &&
cd efs-csi-driver &&
./deploy-aws-efs-csi-driver-using-helm.sh

##
## To create an EFS filesystem, only if it has not been created yet. 
## Once it is created, create a security group to be attached to EFS mount
## target and then add an EFS mount target to one of the private subnets for
## each of Availability Zones -- us-west-1b and us-west-1c.
##
EFS_FILE_SYSTEM_ID=$(aws efs create-file-system \
--region us-west-1 \
--performance-mode generalPurposem \
--query FileSystemId \
--output text)

EFS_MOUNT_TARGET_SG_ID=$(aws ec2 create-security-group \
--group-name security-group-for-efs-mount-target \
--description "Security group for EFS mount target in the StoutEksCluster" \
--vpc-id xxxxx \
--query GroupId \
--output text)

aws ec2 authorize-security-group-ingress \
--group-id $EFS_MOUNT_TARGET_SG_ID \
--protocol tcp \
--port 2049 \
--cidr x.x.x.x/x

aws efs create-mount-target \
--file-system-id $EFS_FILE_SYSTEM_ID \
--subnet-id subnet-xxxxx \
--security-groups $EFS_MOUNT_TARGET_SG_ID

aws efs create-mount-target \
--file-system-id EFS_FILE_SYSTEM_ID \
--subnet-id subnet-xxxxx \
--security-groups $EFS_MOUNT_TARGET_SG_ID 

##
## To deploy EFS Persistent Volume and EFS Persistent Volume Claim
##
kubectl deploy -f pv/efs-pv.yaml

##
##
##
## Now you are ready to create Kubernetes namespaces and deploy resources
## in the Kubernetes cluster.
##
##
##

##
## To create Kubernetes namespaces.
##
kubectl create namespace dev
kubectl create namespace production
kubectl create namespace gitlab

##
## To deploy Configmaps
##
kubectl deploy -f configmap/postgres-configmap.yaml
kubectl deploy -f configmap/cubejs-configmap.ymal

##
## To deploy Secrets
##
kubectl deploy -f secret/gitlab-container-registry-secret.yaml


