# Monitoring EC2 Instance
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.monitoring_instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  subnet_id              = aws_subnet.public[0].id

  associate_public_ip_address = true

  user_data = base64encode(file("${path.module}/monitoring-userdata.sh"))

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-monitoring-server"
    Type = "Monitoring"
  })
}

# Elastic IP for Monitoring
resource "aws_eip" "monitoring" {
  instance = aws_instance.monitoring.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.app_name}-monitoring-eip"
  })

  depends_on = [aws_internet_gateway.main]
}
