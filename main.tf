
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
  policy = "${file("s3policy.json")}"
}

resource "aws_iam_role_policy" "Cloudwatch_logs_policy" {
  name        = "cloudwatch_access_policy"
  role		= "${aws_iam_role.Ec2-S3.id}"
  policy = "${file("cloudlogpolicy.json")}"

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
#subnet_id = " "
#security_groups = [""]
iam_instance_profile = "${aws_iam_role.Ec2-S3.id}"
user_data = "${file("userdata.sh")}"
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
		"sudo service awslogs restart",
		]
	
	}
}