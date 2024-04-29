variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "domain" {
  type = string
}

variable "dns_name" {
  type = string
}

variable "api_gate" {
  type = map(string)
  
}

variable "config_bucket" {
  type = string
}


variable "squidex_uri" {
  type = string
}


variable "cognito_pool_id" {
  type = map(any)
}

variable "certificate" {
  type = string
}

variable "google_analytics_api_key" {
  type = string
}

variable "google_recaptcha_site_key" {
  type = string
}

variable "google_recaptcha_secret_key" {
  type = string
}


variable "project_version" {
  type = list(object({
    project = string
    version     = string
  }))
  description = "List of projects and version"
  default = []
}


