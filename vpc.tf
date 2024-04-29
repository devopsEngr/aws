resource "aws_lb" "this" {
  name               = "${var.app}-apigw-lb-link"
  internal           = true
  load_balancer_type = "network"
  subnets = var.subnets
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_api_gateway_vpc_link" "this" {
  name        = "${var.app}-apigw-vpc-link"
  target_arns = [aws_lb.this.arn]
}

resource "aws_lb_target_group" "this" {
  name        = "${var.app}-vpc-link-alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.internal_alb_arn
  port             = 80
}
