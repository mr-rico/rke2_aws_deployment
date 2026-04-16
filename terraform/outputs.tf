resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content = templatefile("${path.module}/inventory.tftpl", {
    servers = [for i in aws_instance.servers : {
      name       = i.tags.Name
      public_ip  = i.public_ip
      private_ip = i.private_ip
    }]
    agents = [for i in aws_instance.agents : {
      name       = i.tags.Name
      public_ip  = i.public_ip
      private_ip = i.private_ip
    }]
  })
}

resource "local_file" "nlb_dns_name" {
  filename = "${path.module}/nlb_dns_name.txt"
  content  = aws_lb.ingress.dns_name
}

resource "local_file" "kube_api_endpoint" {
  filename = "${path.module}/kube_api_endpoint.txt"
  content  = "https://${aws_instance.servers[0].public_ip}:6443"
}

output "server_public_ips" {
  value = aws_instance.servers[*].public_ip
}

output "agent_public_ips" {
  value = aws_instance.agents[*].public_ip
}

output "nlb_dns_name" {
  value = aws_lb.ingress.dns_name
}

output "kube_api_endpoint" {
  value = "https://${aws_instance.servers[0].public_ip}:6443"
}
