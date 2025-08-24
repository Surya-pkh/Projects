# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.jenkins_instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id              = aws_subnet.public[0].id
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/jenkins-userdata.sh", {
    cluster_name = var.cluster_name
    region       = var.region
  }))

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-jenkins-server"
    Type = "Jenkins"
  })
}

# Elastic IP for Jenkins
resource "aws_eip" "jenkins" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.app_name}-jenkins-eip"
  })

  depends_on = [aws_internet_gateway.main]
}
