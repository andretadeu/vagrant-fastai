#!/bin/bash

set -efu -o pipefail

source $(pwd)/setup/colors.sh

# Create the file vagrant_config.yml for AWS, which contain all the configuration needed
# to run the AWS EC2 instance through Vagrant
#
# Parameters:
# access_key_id: AWS Access Key.
# secret_access_key: AWS Secret Key.
# ssh_private_key_path: The full path to the SSH key that will be used to connect to an AWS EC2 instance.
# aws_keypair_name: The name of SSH key pair.
# aws_security_groups_ids: A list of all security group that the AWS EC2 instance will belong to.
# aws_subnet_id: The ID of the subnet_id.
# aws_ami: The AWS AMI, which one will be used to create the AWS EC2 instance.
# aws_instance_type: AWS EC2 instance type, e.g. t2.xlarge, p2.xlarge.
# aws_region: AWS region.
create_vagrant_config_aws() {
  if [ "$#" -ne 9 ]
  then
    echo "$1"
    echo "$2"
    echo "$3"
    echo "$4"
    echo "$5"
    echo "$6"
    echo "$7"
    echo "$8"
    echo "$9"

    printf "${Red} Invalid number of parameters.\n\n"
    printf "${BYellow} The parameters that should be passed are:\n"
    printf "${BYellow} access_key_id: AWS Access Key\n"
    printf "${BYellow} secret_access_key: AWS Secret Key\n"
    printf "${BYellow} ssh_private_key_path: The full path to the SSH key that will be used to connect to an AWS EC2 instance\n"
    printf "${BYellow} aws_keypair_name: The name of SSH key pair\n"
    printf "${BYellow} aws_security_groups_ids: A list of all security group that the AWS EC2 instance will belong to\n"
    printf "${BYellow} aws_subnet_id: The ID of the subnet_id\n"
    printf "${BYellow} aws_ami: The AWS AMI, which one will be used to create the AWS EC2 instance\n"
    printf "${BYellow} aws_instance_type: AWS EC2 instance type, e.g. t2.xlarge, p2.xlarge\n"
    printf "${BYellow} aws_region: AWS region\n"
    exit 5
  fi
  local access_key_id="$1"
  local secret_access_key="$2"
  local ssh_private_key_path="$3"
  local aws_keypair_name="$4"
  local aws_security_groups_ids="$5"
  local aws_subnet_id="$6"
  local aws_ami="$7"
  local aws_instance_type="$8"
  local aws_region="$9"

  echo "access_key_id: ${access_key_id}" > vagrant_config.yml
  echo "secret_access_key: ${secret_access_key}" >> vagrant_config.yml
  echo "ssh_private_key_path: ${ssh_private_key_path}" >> vagrant_config.yml
  echo "aws_keypair_name: ${aws_keypair_name}" >> vagrant_config.yml
  echo "aws_security_groups_ids: ${aws_security_groups_ids}" >> vagrant_config.yml
  echo "aws_subnet_id: ${aws_subnet_id}" >> vagrant_config.yml
  echo "aws_ami: ${aws_ami}" >> vagrant_config.yml
  echo "aws_instance_type: ${instance_type}" >> vagrant_config.yml
  echo "aws_region: ${aws_region}" >> vagrant_config.yml
}
