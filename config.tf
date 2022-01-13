#################################################
# General Configuration and Settings
#################################################

locals {
  env             = var.env
  is_prod         = (local.env == "prod" || local.env == "production")
  use_subdom      = !local.is_prod
  env_prefix      = (local.is_prod ? "" : "${var.env}-")
  env_subdom      = (local.is_prod ? "" : "${var.env}.")
  region          = "us-east-1"
  dev_endpoint    = var.local_dev_endpoint
  app_name        = var.app_name
  app_slug        = lower(replace(var.app_name, "/[\\s\\W]+/", "-"))
  app_domain_root = var.app_domain
  app_domain      = "${local.env_subdom}${var.app_domain}"
  api_domain      = "api.${local.app_domain}"
  auth_domain     = "id.${local.app_domain}"
  web_app_domain  = "app.${local.app_domain}"
  cert_sans       = ["${local.app_domain}", local.api_domain, local.web_app_domain, local.auth_domain, "*.${local.app_domain}"]
  lambda_archs    = ["arm64"]
  cognito = {
    user_pool_name  = "${local.app_slug}-${local.env_prefix}users"
    authorizer_name = "${local.app_slug}-${local.env_prefix}authorizer"
    passwords       = var.password_rules
    id_token = {
      units    = var.token_validity.id_token.units
      duration = var.token_validity.id_token.duration
    }
    access_token = {
      units    = var.token_validity.access_token.units
      duration = var.token_validity.access_token.duration
    }
    refresh_token = {
      units    = var.token_validity.refresh_token.units
      duration = var.token_validity.refresh_token.duration
    }
  }
  default_tags = marge({
    Name      = local.app_name
    Domain    = local.app_domain_root
    Subdomain = local.app_domain
  }, var.tags)
  data_table = {
    name     = "${local.app_slug}-${local.env_prefix}data"
    hash_key = "pk"
    sort_key = "sk"
  }
  api_gateway = {
    name        = "${local.app_slug}-${local.env_prefix}api"
    stage       = var.env
    description = "The ${local.app_name} API Gateway."
  }
  roles = {
    lambda_exec    = "${local.app_slug}-${local.env_prefix}lambda-exec"
    billing_access = "${local.app_slug}-${local.env_prefix}lambda-billing"
  }
  idp_names = [for idp in var.identity_providers : idp.name]
  lambda_routes = { for obj in
    flatten(
      flatten([for key, lambda in var.lambda_configs :
        flatten([for ri, route in tolist(lambda.routes) : {
          key    = "${local.env_prefix}${key}${(ri > 0 ? "-${format("%03s", ri)}" : "")}"
          lambda = key
          path   = route.path
          method = route.method
          anon   = lambda.anonymous
          auth   = (lambda.anonymous ? "NONE" : "JWT")
        }])
      ])
    ) : obj.key => obj
  }
  token_map = {
    "$DATA_TABLE_NAME" = local.data_table.name
  }
  token_keys = keys(local.token_map)
}
