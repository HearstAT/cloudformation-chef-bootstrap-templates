#!/bin/bash -xev

#### UserData Chef HA Helper Script
### Script Params, exported in Cloudformation
# ${NODENAME} == Node Pre-fix passed per instance creation
# ${S3BUCKET} == S3 Bucket to pull data from
# ${VALIDATOR_PEM} == ValidatorPem
# ${DATABAG_SECRET} == DatabagSecret
# ${REGION} == AWS::Region
# ${ACCESS_KEY} == HostKeys
# ${SECRET_KEY} == {"Fn::GetAtt" : [ "HostKeys", "SecretAccessKey" ]}
# ${CHEF_URL} == ChefServerURL
# ${HOSTNAME} == Nodename or Server URL
# ${CHEF_GROUP} == ChefGroup
# ${CHEF_ROLE} == ChefRole
###

export NODE_NAME=${NODENAME}-$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Add chef repo
curl -s https://packagecloud.io/install/repositories/chef/stable/script.deb.sh | bash

# Install cfn bootstraping tools
easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz

# Install awscli
pip install awscli

# Set hostname
hostname ${HOSTNAME} || error_exit 'Failed to set hostname'
echo ${HOSTNAME} > /etc/hostname || error_exit 'Failed to set hostname'

# Run aws config
aws configure set default.region ${REGION}
aws configure set aws_access_key_id ${ACCESS_KEY}
aws configure set aws_secret_access_key ${SECRET_KEY}

# Add chef repo
curl -s https://packagecloud.io/install/repositories/chef/stable/script.deb.sh | bash
apt-get update

# Do some chef pre-work
/bin/mkdir -p /etc/chef
/bin/mkdir -p /var/lib/chef
/bin/mkdir -p /var/log/chef

# Install Chef
apt-get install -y chef || error_exit 'Failed to install chef'

# Get client pem
aws s3 cp s3://${S3BUCKET}/${VALIDATOR_PEM} /etc/chef/validation.pem || error_exit 'Failed to get Validation Pem'

# Get databag secret
aws s3 cp s3://${S3BUCKET}/${DATABAG_SECRET} /etc/chef/encrypted_data_bag_secret || error_exit 'Failed to get Data Bag Secret'

# Create first-boot.json
cat > "/etc/chef/first-boot.json" << EOF
{
   "run_list" :[
    "role[${CHEF_ROLE}]"
   ]
}
EOF
# Create Client.rb
/bin/echo 'log_location     STDOUT' >> /etc/chef/client.rb
/bin/echo -e "chef_server_url  \"${CHEF_URL}/organizations/${CHEF_GROUP}\"" >> /etc/chef/client.rb
/bin/echo -e "validation_client_name \"${CHEF_GROUP}-validator\"" >> /etc/chef/client.rb
/bin/echo -e "node_name  \"${NODE_NAME}\"" >> /etc/chef/client.rb
/bin/echo 'encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"' >> /etc/chef/client.rb
sudo su -l -c 'chef-client -j /etc/chef/first-boot.json' || error_exit 'Failed to run chef-client'
