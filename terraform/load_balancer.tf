resource "aws_lb" "ingress" {
  name               = substr(replace("${var.name_prefix}-ingress", "_", "-"), 0, 32)
  load_balancer_type = "network"
  internal           = false
  subnets            = values(aws_subnet.public)[*].id

  tags = {
    Name = "${var.name_prefix}-ingress"
  }
}

resource "aws_lb_target_group" "http" {
  name        = substr(replace("${var.name_prefix}-http", "_", "-"), 0, 32)
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.this.id

  health_check {
    protocol = "TCP"
    port     = "80"
  }
}

resource "aws_lb_target_group" "https" {
  name        = substr(replace("${var.name_prefix}-https", "_", "-"), 0, 32)
  port        = 443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = aws_vpc.this.id

  health_check {
    protocol = "TCP"
    port     = "443"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = 443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}

resource "aws_lb_target_group_attachment" "http_agents" {
  count            = var.agent_count
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.agents[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "https_agents" {
  count            = var.agent_count
  target_group_arn = aws_lb_target_group.https.arn
  target_id        = aws_instance.agents[count.index].id
  port             = 443
}
