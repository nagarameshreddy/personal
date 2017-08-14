#!/bin/bash
sudo yum install awslogs iwatch squid -y
sudo service squid start
sudo chkconfig squid on
echo "*/10 * * * * aws s3 sync s3://bucket-name/ /etc/squid/ --exclude "*" --include "squid.conf"" >> /etc/crontab
echo "@reboot iwatch /etc/squid/squid.conf -c 'sudo service squid restart'" >> /etc/crontab