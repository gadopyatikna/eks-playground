resource "aws_lb" "client_webapp" {
  name               = "${var.name}-${var.environment}-client-webapp"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.client_web_alb.id]
  subnets            = aws_subnet.public[*].id

  drop_invalid_header_fields = true
  idle_timeout               = 60

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-client-webapp"
  })
}

resource "aws_lb_target_group" "client_webapp" {
  name        = "${var.name}-${var.environment}-client-webapp"
  port        = var.client_webapp_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    enabled             = true
    path                = "/ready"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
  }

  deregistration_delay = 30

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-client-webapp"
  })
}

resource "aws_lb_listener" "client_webapp_http" {
  load_balancer_arn = aws_lb.client_webapp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "client_webapp_https" {
  load_balancer_arn = aws_lb.client_webapp.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client_webapp.arn
  }
}
