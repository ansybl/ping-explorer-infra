output "load_balancer_ip" {
  value = module.load_balancer[0].external_ip
}
