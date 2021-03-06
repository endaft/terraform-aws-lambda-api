#################################################
# AWS Cognito - User Pool & Authentication
#################################################
resource "aws_cognito_user_pool_ui_customization" "app" {
  count = local.is_anon ? 0 : 1

  client_id    = aws_cognito_user_pool_client.app[0].id
  user_pool_id = aws_cognito_user_pool_domain.app[0].user_pool_id

  css        = file(local.is_anon || var.cognito_css_path == "" ? "${path.module}/empty.file" : var.cognito_css_path)
  image_file = filebase64(local.is_anon || var.cognito_logo_path == "" ? "${path.module}/empty.file" : var.cognito_logo_path)
}

resource "aws_cognito_user_pool_client" "app" {
  count = local.is_anon ? 0 : 1

  name         = "${local.cognito.user_pool_name}-client"
  user_pool_id = aws_cognito_user_pool.app[0].id

  # Default redirect * MUST * be in the callbacks
  default_redirect_uri = "https://${local.app_domain}"
  callback_urls = [
    local.dev_endpoint,
    "https://${local.app_domain}",
    "https://${local.web_app_domain}"
  ]

  allowed_oauth_flows  = ["code"]
  allowed_oauth_scopes = ["openid", "profile", "email"]
  supported_identity_providers = concat(
    ["COGNITO"],    // Supports self-registration via the user pool UI
    local.idp_names // Support federated and social login and registration
  )

  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"
  allowed_oauth_flows_user_pool_client = true

  id_token_validity      = local.cognito.id_token.duration
  access_token_validity  = local.cognito.access_token.duration
  refresh_token_validity = local.cognito.refresh_token.duration

  token_validity_units {
    id_token      = local.cognito.id_token.units
    access_token  = local.cognito.access_token.units
    refresh_token = local.cognito.refresh_token.units
  }
}

resource "aws_cognito_user_pool_domain" "app" {
  count = local.is_anon ? 0 : 1

  domain          = local.auth_domain
  certificate_arn = aws_acm_certificate.app.arn
  user_pool_id    = aws_cognito_user_pool.app[0].id
}

resource "aws_cognito_user_pool" "app" {
  count = local.is_anon ? 0 : 1

  name                     = local.cognito.user_pool_name
  alias_attributes         = ["phone_number", "email", "preferred_username"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = local.cognito.passwords.minimum_length
    require_numbers   = local.cognito.passwords.require_numbers
    require_symbols   = local.cognito.passwords.require_symbols
    require_lowercase = local.cognito.passwords.require_lowercase
    require_uppercase = local.cognito.passwords.require_uppercase

    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  username_configuration {
    case_sensitive = false
  }

  schema {
    name                = "preferred_username"
    attribute_data_type = "String"
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      schema
    ]
  }
}
