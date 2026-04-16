locals {
  server_names = [for i in range(var.server_count) : format("%s-server-%02d", var.name_prefix, i + 1)]
  agent_names  = [for i in range(var.agent_count) : format("%s-agent-%02d", var.name_prefix, i + 1)]
  subnet_ids   = values(aws_subnet.public)[*].id
}

resource "aws_instance" "servers" {
  count                       = var.server_count
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.instance_type_server
  subnet_id                   = local.subnet_ids[count.index % length(local.subnet_ids)]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.cluster.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = local.server_names[count.index]
    Role = "server"
  }
}

resource "aws_instance" "agents" {
  count                       = var.agent_count
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.instance_type_agent
  subnet_id                   = local.subnet_ids[count.index % length(local.subnet_ids)]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.cluster.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = local.agent_names[count.index]
    Role = "agent"
  }
}
