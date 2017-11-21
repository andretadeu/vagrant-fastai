# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

CONF = YAML::load_file("vagrant_config.yml")

Vagrant.configure("2") do |config|
  config.vm.hostname = 'fast-ai-vm'
  config.vm.network "forwarded_port", guest: 8888, host: 8888, host_ip: "127.0.0.1"

  config.vm.provider "aws" do |aws, override|
    override.vm.box = "fast-ai-vm"
    override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"

    aws.access_key_id = CONF["access_key_id"]
    aws.secret_access_key = CONF["secret_access_key"]
    aws.keypair_name = CONF["aws_keypair_name"]
    aws.security_groups = CONF["aws_security_groups_ids"]
    aws.subnet_id = CONF["aws_subnet_id"]
    aws.ami = CONF["aws_ami"]
    aws.instance_type = CONF["aws_instance_type"]
    aws.region = CONF["aws_region"]
    aws.elastic_ip = true

    aws.tags = {
      'Name' => "fast-ai"
    }

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = CONF["ssh_private_key_path"]
    #aws.block_device_mapping = [{
    #  'DeviceName' => '/dev/sda1',
    #  'Ebs.VolumeSize' => 20,
    #  'Ebs.VolumeType' => 'gp2',
    #  'Ebs.DeleteOnTermination' => 'true'
    #}]
  end
  #config.vm.provision "shell", inline: <<-SHELL
  #  sudo apt update -q && sudo apt install -yq language-pack-pt
  #SHELL
end
