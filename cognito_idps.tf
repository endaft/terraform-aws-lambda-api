####################################################
# AWS Cognito IdP - OID, IdP and Social Connections
#
# For more detailed info, see:
# https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-social-idp.html
# https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_CreateIdentityProvider.html
#
####################################################
locals {
  vars_regex = "^(.+)_var$"
}

resource "aws_cognito_identity_provider" "app" {
  for_each = { for idp in var.identity_providers : idp.name => idp }

  user_pool_id  = aws_cognito_user_pool.app.id
  provider_name = each.key
  provider_type = each.value.type
  provider_details = { for k, v in each.value.details :
    (length(regexall(local.vars_regex, k)) > 0 ? regex(local.vars_regex, k)[0] : k) =>
  (length(regexall(local.vars_regex, k)) > 0 ? v : v) }
  attribute_mapping = each.value.mapping
}
