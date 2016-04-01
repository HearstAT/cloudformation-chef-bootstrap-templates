# Self Bootstrap to Chef Cloudformation Templates

These templates utilize a way to avoid having to use knife bootstrap and/or knife ec2 to get AWS instance built and into your chef server.

## userdata.ps1

Powershell Script to be pulled down at build time, creates the client.rb in UTF8 encoding with BOM.

## userdata.sh

Bash script to be pulled down at build time, creates the client.rb, first-boot.json, and acquires the validation/encrypted_data_bag_secret keys.
