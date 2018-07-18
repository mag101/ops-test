/* Setup our aws provider */
provider "aws" {
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
}

resource "aws_security_group" "ssh_and_http" {
  name = "allow_ssh_and_http"
  description = "Allow SSH and HTTP traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 443
      to_port = 443
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "master" {
  ami           = "${aws_security_group.ssh_and_http.name}"
  instance_type = "t2.micro"
  security_groups = ["all"]
  key_name = "mgudzenko"

    connection {
      user     = "ubuntu"
    }

  provisioner "file" {
    source      = "proj/creds/jenkins.pub"
    destination = "/home/ubuntu/.ssh/jenkins.pub"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo docker swarm init",
      "sudo docker swarm join-token --quiet worker > /home/ubuntu/token",
      "cat /home/ubuntu/.ssh/jenkins.pub >> /home/ubuntu/.ssh/authorized_keys",
      "sudo apt-get install -y lighttpd",
      "sudo useradd -g docker web-data"
    ]

  }
  provisioner "file" {
    source      = "proj/lighttpd"
    destination = "/etc"

  }
  provisioner "remote-exec" {
    inline = [
         "sudo service lighttpd restart"
         ]
}

  tags = { 
    Name = "swarm-master"
  }
}

resource "aws_instance" "slave" {
  ami           = "${aws_security_group.ssh_and_http.name}"
  instance_type = "t2.micro"
  security_groups = ["all"]
  key_name = "mgudzenko"


  provisioner "local-exec" {
      command = "scp -3 -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null  ubuntu@${aws_instance.master.public_ip}:/home/ubuntu/token ubuntu@${aws_instance.slave.public_ip}:/home/ubuntu/token"

    connection {
    user     = "mg"
    }

  }

  provisioner "file" {
    source      = "proj/creds/jenkins.pub"
    destination = "/home/ubuntu/.ssh/jenkins.pub"

    connection {
    user     = "ubuntu"
    }

  }


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo docker swarm join --token $(cat /home/ubuntu/token) ${aws_instance.master.private_ip}:2377",
      "cat /home/ubuntu/.ssh/jenkins.pub >> /home/ubuntu/.ssh/authorized_keys"
    ]
  connection {
    user     = "ubuntu"
    }

  }

  tags = { 
    Name = "swarm-slave"
  }
}


resource "aws_instance" "jenkins" {
    ami = "ami-ba602bc2"
    instance_type = "t2.micro"
    key_name = "mgudzenko"
    security_groups = ["${aws_security_group.ssh_and_http.name}"]

    connection {
    user     = "ubuntu"
    }

  provisioner "file" {
    source      = "proj/creds/jenkins"
    destination = "/tmp/jenkins"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt-get update",
      "sudo apt-get install -y jenkins openjdk-8-jre-headless",
      "sudo mkdir /var/lib/jenkins/.ssh",
      "sudo cp /tmp/jenkins /var/lib/jenkins/.ssh/id_rsa",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh",
      "sudo chmod 0600 /var/lib/jenkins/.ssh/id_rsa",
      "sudo echo ${aws_instance.master.private_ip} >/var/lib/jenkins/swarm-m-ip"
      ]
    }

    tags {
        Name = "jenkins"
    }
}

