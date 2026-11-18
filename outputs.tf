output "deployment_summary" {
  description = "Зведена інформація про розгорнуте середовище (Blue/Green)"
  value = {
    workspace      = terraform.workspace
    environment    = local.env_prefix
    traffic_status = local.is_active ? "ACTIVE (100% traffic)" : "STANDBY (0% traffic - ready for switch)"
    vpc_id         = module.networking.vpc_id
    nat_gateways   = module.networking.nat_gateway_ids
    lb_endpoint    = module.compute.lb_endpoint
    compute_pool   = module.compute.asg_pool_info
    app_nodes      = module.compute.app_instance_ids
    db_endpoint    = module.database.db_endpoint
    db_secret_arn  = module.secrets.secret_arn
    alerts_topic   = module.monitoring.sns_topic_arn
  }
}