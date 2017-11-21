# vagrant-fastai

A Vagrant-managed version of AWS EC2 instance for Fast.ai course.

## First steps

To be able to benefit from these scripts, you must install [Vagrant](http://www.vagrantup.com).

## Setup

To setup AWS environment to be able to create and destroy AWS EC2 instances, run the command below:

```
$ bash setup/setup_aws.sh create
```

## Running an EC2 instance

To run an EC2 instance, you just need to execute the command:

```
$ vagrant up --provider=aws
```

If you need to access the terminal in EC2 instance, just use the following command:

```
vagrant ssh
```

To stop the instance:

```
$ vagrant halt
```

To destroy the instance:

```
$ vagrant destroy
```

## Removing all settings from AWS:

Once you need no Fast.ai setups required to run the lessons and homeworks, you can run the command below to remove the security group, VPC, route table, subnet, and Internet gateway created by setup script by just executing the command below:

```
$ bash setup/setup_aws.sh destroy
```

## Disclaimer

Avoid reusing the security group, VPC, route table, subnet, and Internet gateway created for the course to other activities because you may have to terminate all these resources prior destroying all the setup done to Fast.ai course.
