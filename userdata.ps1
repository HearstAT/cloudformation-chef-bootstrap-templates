$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
$instanceid = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/instance-id
$chefclientrb = 'C:\chef\client.rb'
$chefboot = 'C:\chef\first-boot.json'

## Create client.rb
[System.IO.File]::WriteAllLines($chefclientrb,'log_location STDOUT', $Utf8NoBomEncoding)
[System.IO.File]::AppendAllText($chefclientrb,'chef_server_url ' + '"' + $chefurl + '/organizations/' + $chefgroup + '"' + ([Environment]::NewLine), $Utf8NoBomEncoding)
[System.IO.File]::AppendAllText($chefclientrb,'validation_client_name ' + '"' + $chefgroup + '-validator' + '"' + ([Environment]::NewLine), $Utf8NoBomEncoding)
[System.IO.File]::AppendAllText($chefclientrb,'node_name ' + '"' + $nodename + '-' + $instanceid + '"' + ([Environment]::NewLine), $Utf8NoBomEncoding)
[System.IO.File]::AppendAllText($chefclientrb,'encrypted_data_bag_secret  "C:\chef\encrypted_data_bag_secret"' + ([Environment]::NewLine), $Utf8NoBomEncoding)

## Create First Boot json w/ chef role
[System.IO.File]::WriteAllLines($chefboot,'{"run_list":["role[' + $chefrole + ']"]}', $Utf8NoBomEncoding)
