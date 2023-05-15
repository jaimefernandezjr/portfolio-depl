#defining the provider block
provider "aws" {
  region  = "ap-southeast-1"
  profile = "default"
}

#aws instance creation
resource "aws_instance" "os1" {
  ami           = "ami-0a72af05d27b49ccb"
  instance_type = "t2.micro"
  key_name = "tf-ans-demo-keypair"
  tags = {
    Name = "TerraformOS"
  }
}

#IP of aws instance retrieved
output "op1" {
  value = aws_instance.os1.public_ip
}


#IP of aws instance copied to a file ip.txt in local system
resource "local_file" "ip" {
  content  = aws_instance.os1.public_ip
  filename = "ip.txt"
}


#ebs volume created
resource "aws_ebs_volume" "ebs" {
  availability_zone = aws_instance.os1.availability_zone
  size              = 1
  tags = {
    Name = "myterraebs"
  }
}


#ebs volume attached
resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.ebs.id
  instance_id  = aws_instance.os1.id
  force_detach = true
}


#device name of ebs volume retrieved
output "op2" {
  value = aws_volume_attachment.ebs_att.device_name
}

#connecting to the Ansible control node using SSH connection

# Make sure that you update the variable to the key you created and stored locally

resource "null_resource" "nullremote1" {
  depends_on = [aws_instance.os1]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./tf-ans-demo-keypair.pem")
    host        = aws_instance.os1.public_ip
    timeout = "1m"
  }
  #copying the ip.txt file to the Ansible control node from local system

  provisioner "file" {
    source      = "ip.txt"
    destination = "/tmp/ip.txt"
  }

}

#connecting to the Linux OS having the Ansible playbook
resource "null_resource" "nullremote2" {
  depends_on = [aws_instance.os1]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./tf-ans-demo-keypair.pem")
    host        = aws_instance.os1.public_ip
    timeout = "1m"
  }

  provisioner "file" {
    source      = "instance.yml"
    destination = "/tmp/instance.yml"
  }

  # # #command to run ansible playbook on remote Linux OS
  provisioner "remote-exec" {

    inline = [
      "cd /tmp",
      "ls -la",
      "sudo apt update -y",
      "sudo apt-add-repository ppa:ansible/ansible -y",
      "sudo apt install -y ansible",
      "ansible-playbook /tmp/ansible-playbook.yml -i /tmp/ip.txt"
    ]
  }
}
