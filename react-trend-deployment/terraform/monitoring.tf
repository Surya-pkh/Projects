# Create an EC2 instance for Prometheus and Grafana
resource "aws_instance" "monitoring" {
  ami           = var.ami_id
  instance_type = var.monitoring_instance_type
  subnet_id     = module.vpc.public_subnet_ids[0]  # Using the first public subnet
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker

              # Create directories for persistent storage
              mkdir -p /prometheus-data /grafana-data

              # Start Prometheus
              docker run -d \
                --name prometheus \
                -p 9090:9090 \
                -v /prometheus-data:/prometheus \
                -v ${path.module}/prometheus.yml:/etc/prometheus/prometheus.yml \
                prom/prometheus

              # Start Grafana
              docker run -d \
                --name grafana \
                -p 3000:3000 \
                -v /grafana-data:/var/lib/grafana \
                grafana/grafana
              EOF

  tags = {
    Name = "monitoring-server"
  }
}

# Security group for monitoring
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-security-group"
  description = "Security group for Prometheus and Grafana"
  vpc_id      = module.vpc.vpc_id  # Using the VPC ID from VPC module

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}
