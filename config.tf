#################################################
# General Configuration and Settings
#################################################

locals {
  env             = var.env
  is_anon         = var.anonymous
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
  web_apps        = var.web_apps
  cert_sans       = ["${local.app_domain}", local.api_domain, local.web_app_domain, local.auth_domain, "*.${local.app_domain}"]
  s3w_origin_id   = "origin-${local.app_slug}"
  idps            = local.is_anon ? var.identity_providers : []
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
  default_tags = merge({
    Name      = local.app_name
    Domain    = local.app_domain_root
    Subdomain = local.app_domain
  }, var.tags)
  api_gateway = {
    name        = "${local.app_slug}-${local.env_prefix}api"
    stage       = var.env
    description = "The ${local.app_name} API Gateway."
  }
  roles = {
    lambda_exec = "${local.app_slug}-${local.env_prefix}lambda-exec"
  }
  idp_names      = [for idp in var.identity_providers : idp.name]
  web_apps_count = length(local.web_apps)
  web_apps_files = { for obj in tolist(flatten([for app, dirPath in local.web_apps :
    tolist([for f in fileset(dirPath, "**") : {
      target = local.web_apps_count > 1 ? "${app}/${f}" : f
      source = "${dirPath}/${f}"
    }])
  ])) : obj.target => obj.source }
  lambda_routes = { for obj in
    flatten(
      flatten([for key, lambda in var.lambda_configs :
        flatten([for ri, route in tolist(lambda.routes) : {
          key    = "${local.env_prefix}${key}${(ri > 0 ? "-${format("%03s", ri)}" : "")}"
          lambda = key
          path   = route.path
          method = route.method
          anon   = lambda.anonymous || local.is_anon
          auth   = (lambda.anonymous ? "NONE" : "JWT")
        }])
      ])
    ) : obj.key => obj
  }
  lambdas_cloudfront = { for key in compact([for k, l in var.lambda_configs : l.cloudfront_event != "" ? k : ""]) : key => lookup(var.lambda_configs, key) }
  lambda_endpoints   = { for key in compact([for k, l in var.lambda_configs : length(l.routes) > 0 ? k : ""]) : key => lookup(var.lambda_configs, key) }
  lambda_routes_anon = { for key in compact([for k, l in local.lambda_routes : l.anon ? k : ""]) : key => lookup(local.lambda_routes, key) }
  lambda_routes_auth = { for key in compact([for k, l in local.lambda_routes : !l.anon ? k : ""]) : key => lookup(local.lambda_routes, key) }
  token_map          = var.token_map
  token_keys         = keys(local.token_map)
  mime_map = {
    "aac"    = "audio/aac"
    "abw"    = "application/x-abiword"
    "arc"    = "application/x-freearc"
    "avif"   = "image/avif"
    "avi"    = "video/x-msvideo"
    "azw"    = "application/vnd.amazon.ebook"
    "bin"    = "application/octet-stream"
    "bmp"    = "image/bmp"
    "bz"     = "application/x-bzip"
    "bz2"    = "application/x-bzip2"
    "cda"    = "application/x-cdf"
    "csh"    = "application/x-csh"
    "css"    = "text/css"
    "csv"    = "text/csv"
    "doc"    = "application/msword"
    "docx"   = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    "eot"    = "application/vnd.ms-fontobject"
    "epub"   = "application/epub+zip"
    "gz"     = "application/gzip"
    "gif"    = "image/gif"
    "htm"    = "text/html"
    "html"   = "text/html"
    "ico"    = "image/vnd.microsoft.icon"
    "ics"    = "text/calendar"
    "jar"    = "application/java-archive"
    "jpeg"   = "image/jpeg"
    "jpg"    = "image/jpeg"
    "js"     = "text/javascript"
    "json"   = "application/json"
    "jsonld" = "application/ld+json"
    "mid"    = "audio/midi audio/x-midi"
    "midi"   = "audio/midi audio/x-midi"
    "mjs"    = "text/javascript"
    "mp3"    = "audio/mpeg"
    "mp4"    = "video/mp4"
    "mpeg"   = "video/mpeg"
    "mpkg"   = "application/vnd.apple.installer+xml"
    "odp"    = "application/vnd.oasis.opendocument.presentation"
    "ods"    = "application/vnd.oasis.opendocument.spreadsheet"
    "odt"    = "application/vnd.oasis.opendocument.text"
    "oga"    = "audio/ogg"
    "ogv"    = "video/ogg"
    "ogx"    = "application/ogg"
    "opus"   = "audio/opus"
    "otf"    = "font/otf"
    "png"    = "image/png"
    "pdf"    = "application/pdf"
    "php"    = "application/x-httpd-php"
    "ppt"    = "application/vnd.ms-powerpoint"
    "pptx"   = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    "rar"    = "application/vnd.rar"
    "rtf"    = "application/rtf"
    "sh"     = "application/x-sh"
    "svg"    = "image/svg+xml"
    "swf"    = "application/x-shockwave-flash"
    "tar"    = "application/x-tar"
    "tif"    = "image/tiff"
    "tiff"   = "image/tiff"
    "ts"     = "video/mp2t"
    "ttf"    = "font/ttf"
    "txt"    = "text/plain"
    "vsd"    = "application/vnd.visio"
    "wasm"   = "application/wasm"
    "wav"    = "audio/wav"
    "weba"   = "audio/webm"
    "webm"   = "video/webm"
    "webp"   = "image/webp"
    "woff"   = "font/woff"
    "woff2"  = "font/woff2"
    "xhtml"  = "application/xhtml+xml"
    "xls"    = "application/vnd.ms-excel"
    "xlsx"   = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    "xml"    = "application/xml"
    "xul"    = "application/vnd.mozilla.xul+xml"
    "zip"    = "application/zip"
    "3gp"    = "video/3gpp"
    "3g2"    = "video/3gpp2"
    "7z"     = "application/x-7z-compressed"
  }
}
