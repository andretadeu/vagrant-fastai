#!/bin/bash

set -efu -o pipefail

if [ $(pwd | grep setup | wc -l) -eq 1 ]
then
  cd ..
fi

source $(pwd)/setup/colors.sh

# Setup the whole AWS environment.
# Since I don't want a bunch of AWS variables lying around in my environment,
# I decided to put them inside this function and set them as local variables
#
# Parameters:
# aws_ami: The AWS AMI, which one will be used to create the AWS EC2 instance.
# aws_instance_type: AWS EC2 instance type, e.g. t2.xlarge, p2.xlarge.
# aws_region: AWS region.
__setup_aws() {

  printf "${BWhite}###########################################################\n"
  printf "${BWhite}Setting up AWS\n"
  printf "${BWhite}###########################################################\n"

  if [ $# -ne 3 ]
  then
    printf "${Red} Invalid number of parameters.\n\n"
    printf "${BYellow} The parameters that should be passed are:\n"
    printf "${BYellow} aws_ami: The AWS AMI, which one will be used to create the AWS EC2 instance\n"
    printf "${BYellow} aws_instance_type: AWS EC2 instance type, e.g. t2.xlarge, p2.xlarge\n"
    printf "${BYellow} aws_region: AWS region\n"
    exit 1
  fi

  local ami="$1"
  local instance_type="$2"
  local region="$3"
  local name="fast-ai"
  local cidr="0.0.0.0/0"

  # Basic awscli install and setup status
  hash aws 2>/dev/null
  if [ $? -ne 0 ]; then
    printf >&2 "${Red}'aws' command line tool required, but not installed. Aborting.\n"
    exit 2
  fi
  if [ -z "$(aws configure get aws_access_key_id)" ]; then
    printf "${Red}AWS credentials not configured. Aborting.\n"
    exit 3
  fi

  # Setup AWS VPC
  local vpcId="$(aws ec2 describe-vpcs --filters Name=tag:Name,Values="$name" --query "Vpcs[0].VpcId")"
  if [ "${vpcId}" == "None" ]
  then
    printf "${BWhite}Fast.ai virtual private cloud does not exist. Creating one.\n"
    local vpcId=$(aws ec2 create-vpc --cidr-block 10.0.0.0/28 --query 'Vpc.VpcId' --output text)
    aws ec2 create-tags --resources $vpcId --tags --tags Key=Name,Value=$name
    aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-support "{\"Value\":true}"
    aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}"
  else
    printf "${Green}Fast.ai virtual private cloud already exists. Skipping.\n"
  fi

  # Setup AWS Internet Gateway
  local internetGatewayId="$(aws ec2 describe-internet-gateways --filter Name=tag:Name,Values="$name"-gateway --query "InternetGateways[0].InternetGatewayId")"
  if [ "${internetGatewayId}" == "None" ]
  then
    printf "${BWhite}Fast.ai Internet Gateway does not exist. Creating one.\n"
    local internetGatewayId=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
    aws ec2 create-tags --resources $internetGatewayId --tags --tags Key=Name,Value=$name-gateway
    aws ec2 attach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId
  else
    printf "${Green}Fast.ai Internet Gateway already exists. Skipping.\n"
  fi

  # Setup AWS subnet
  local subnetId="$(aws ec2 describe-subnets --filter Name=tag:Name,Values="$name"-subnet --query "Subnets[0].SubnetId")"
  if [ "${subnetId}" == "None" ]
  then
    printf "${BWhite}Fast.ai subnet does not exist. Creating one.\n"
    local subnetId=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.0.0.0/28 --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $subnetId --tags --tags Key=Name,Value=$name-subnet
  else
    printf "${Green}Fast.ai subnet already exists. Skipping.\n"
  fi

  # Setup AWS route table
  local routeTableId="$(aws ec2 describe-route-tables --filter Name=tag:Name,Values="$name"-route-table --query "RouteTables[0].RouteTableId")"
  if [ "${routeTableId}" == "None" ]
  then
    printf "${BWhite}Fast.ai route table does not exist. Creating one.\n"
    local routeTableId=$(aws ec2 create-route-table --vpc-id $vpcId --query 'RouteTable.RouteTableId' --output text)
    aws ec2 create-tags --resources $routeTableId --tags --tags Key=Name,Value=$name-route-table
    local routeTableAssoc=$(aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $subnetId --output text)
    aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGatewayId
  else
    printf "${Green}Fast.ai route table already exists. Skipping.\n"
  fi

  # Setup AWS security group
  local securityGroupId="$(aws ec2 describe-security-groups --filters Name=vpc-id,Values="$vpcId" Name=group-name,Values="$name"-security-group --query "SecurityGroups[0].GroupId")"
  if [ "${securityGroupId}" == "None" ]
  then
    printf "${BWhite}Fast.ai security group does not exist. Creating one.\n"
    local securityGroupId=$(aws ec2 create-security-group --group-name $name-security-group --description "SG for fast.ai machine" --vpc-id $vpcId --query 'GroupId' --output text)
    # ssh
    aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr $cidr
    # jupyter notebook
    aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 8888-8898 --cidr $cidr
  else
    printf "Fast.ai security group already exists. Skipping.\n"
  fi

  # Setup AWS key pair
  if [ ! -d ~/.ssh ]
  then
  	mkdir ~/.ssh
  fi

  if [ ! -f ~/.ssh/aws-key-$name.pem ]
  then
  	aws ec2 create-key-pair --key-name aws-key-$name --query 'KeyMaterial' --output text > ~/.ssh/aws-key-$name.pem
  	chmod 400 ~/.ssh/aws-key-$name.pem
  fi

  # Configuring Vagrant AWS configurations
  local access_key_id="$(aws configure get aws_access_key_id)"
  local secret_access_key=""
  read -p "AWS secret key: " secret_access_key
  local securityGroupsIds="[\"${securityGroupId}\"]"
  source $(pwd)/setup/setup_vagrant_aws.sh
  create_vagrant_config_aws $access_key_id $secret_access_key "~/.ssh/aws-key-$name.pem" "aws-key-$name" $securityGroupsIds $subnetId $ami $instance_type $region
}

# Terminate all AWS resources needed to run the AWS instance
__destroy_aws_resources() {
  local name="fast-ai"
  local vpcId="$(aws ec2 describe-vpcs --filters Name=tag:Name,Values="$name" --query "Vpcs[0].VpcId")"
  local internetGatewayId="$(aws ec2 describe-internet-gateways --filter Name=tag:Name,Values="$name"-gateway --query "InternetGateways[0].InternetGatewayId")"
  local subnetId="$(aws ec2 describe-subnets --filter Name=tag:Name,Values="$name"-subnet --query "Subnets[0].SubnetId")"
  local routeTableId="$(aws ec2 describe-route-tables --filter Name=tag:Name,Values="$name"-route-table --query "RouteTables[0].RouteTableId")"
  local securityGroupId="$(aws ec2 describe-security-groups --filters Name=vpc-id,Values="$vpcId" Name=group-name,Values="$name"-security-group --query "SecurityGroups[0].GroupId")"

  if [ "${securityGroupId}" != "None" ]
  then
    printf "${BWhite} Removing AWS security group.\n"
    aws ec2 delete-security-group --group-id "${securityGroupId}"
  else
    printf "${BWhite} AWS security group already removed. Skipping.\n"
  fi

  if [ "${routeTableId}" != "None" ]
  then
    printf "${BWhite} Removing AWS route table.\n"
    local routeTableAssoc=$(aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $subnetId --output text)
    aws ec2 disassociate-route-table --association-id $routeTableAssoc
    aws ec2 delete-route-table --route-table-id $routeTableId
  else
    printf "${BWhite} AWS route table already removed. Skipping.\n"
  fi

  if [ "${internetGatewayId}" != "None" ]
  then
    printf "${BWhite} Removing AWS Internet gateway.\n"
    aws ec2 detach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId
    aws ec2 delete-internet-gateway --internet-gateway-id $internetGatewayId
  else
    printf "${BWhite} AWS Internet gateway already removed. Skipping.\n"
  fi

  if [ "${subnetId}" != "None" ]
  then
    printf "${BWhite} Removing AWS subnet.\n"
    aws ec2 delete-subnet --subnet-id $subnetId
  else
    printf "${BWhite} AWS subnet already removed. Skipping.\n"
  fi

  if [ "${vpcId}" != "None" ]
  then
    printf "${BWhite} Removing AWS VPC.\n"
    aws ec2 delete-vpc --vpc-id $vpcId
  else
    printf "${BWhite} AWS VPC already removed. Skipping.\n"
  fi

  printf "${BWhite}If you want to delete the key-pair, please do it manually.\n"
}

create() {
  local region=$(aws configure get region)
  local ami=""
  if [ $region = "us-west-2" ]; then
    ami="ami-8c4288f4" # Oregon
  elif [ $region = "eu-west-1" ]; then
    ami="ami-b93c9ec0" # Ireland
  elif [ $region = "us-east-1" ]; then
    ami="ami-c6ac1cbc" # Virginia
  elif [ $region = "ap-southeast-2" ]; then
    ami="ami-b93c9ec0" # Sydney
  elif [ $region = "ap-south-1" ]; then
    ami="ami-c53975aa" # Mumbai
  else
    printf "${BYellow}Only us-west-2 (Oregon), eu-west-1 (Ireland), us-east-1 (Virginia), ap-southeast-2 (Sydney), and ap-south-1 (Mumbai) are currently supported."
    exit 6
  fi
  source $(pwd)/setup/setup_vagrant.sh && install_vagrant_plugins
  __setup_aws $ami "p2.xlarge" $region
}

destroy() {
  local isRunning=$(vagrant status | grep default | grep running | wc -l)
  if [ "${isRunning}" -eq 1 ]
  then
    vagrant destroy -f
  fi
  __destroy_aws_resources
}

appHelp() {
  printf "${BWhite}Available options:\n\n"
  printf "${BWhite}  create           - Create a new AWS environment\n"
  printf "${BWhite}  destroy          - Destroy the current AWS environment\n"
  printf "${BWhite}  help             - Print this help message\n"
}

case ${1} in
  create)
    create
    ;;
  destroy)
    destroy
    ;;
  help)
    appHelp
    ;;
  *)
    appHelp
    ;;
esac
