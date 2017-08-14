
resource "aws_iam_role" "Ec2-S3" {
  name = "Ec2-S3"
  assume_role_policy = <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name        = "s3_access_policy"
  role		= "${aws_iam_role.Ec2-S3.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF  
}

resource "aws_iam_role_policy" "Cloudwatch_logs_policy" {
  name        = "s3_access_policy"
  role		= "${aws_iam_role.Ec2-S3.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF  
}

resource "aws_s3_bucket_object" "object" {
  bucket = "your_bucket_name"
  key    = "squid.conf"
  source = "squid.conf"
}


resource "aws_instance" "squidserver" {
ami = "ami-a4c7edb2"
instance_type = "t2.micro"
key_name = "myawskeypair"
subnet_id = " "
security_groups = [""]
iam_instance_profile = ""
user_data = <<EOF
  #!/bin/bash
  sudo yum install awslogs iwatch squid -y
  sudo service squid start
  sudo chkconfig squid on
  echo "*/10 * * * * aws s3 sync s3://bucket-name/ /etc/squid/ --exclude "*" --include "squid.conf"" >> /etc/crontab
  echo "@reboot iwatch /etc/squid/squid.conf -c 'sudo service squid restart'" >> /etc/crontab
  EOF
iam_instance_profile = "${aws_iam_role.Ec2-S3.id}"
tags {
	Name = "Squid Server"
}
provisioner "file" {
	source = "squid.conf"
	destination = "/etc/squid/squid.conf"
	}
provisioner "file" {
	source = "awscli.conf"
	destination = "/etc/awslogs/awscli.conf"
	}	
provisioner "file" {
	source = "awslogs.conf"
	destination = "/etc/awslogs/awslogs.conf"
	}	
provisioner "remote-exec" {
	inline = [
		"sudo service squid restart" ,
		"iwatch /etc/squid/squid.conf -c 'sudo service squid restart'" ,
		"sudo service awslogs restart"
		]
	
	}
}