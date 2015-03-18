#! /bin/bash

fqdn=$(dig +short -x $(ip -4 -o address show eth0 scope global | awk -F'[  /]' '{print $7}'))
host=$(echo $fqdn | awk -F. '{print $1}')

echo "127.0.1.1	$fqdn	$host"