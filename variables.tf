variable "account_share" {
  description = "Account Share"
  type        = list(any)
  default     = []
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
  default     = ""
}

variable "enable_share_with_organization" {
  description = "Share the Route53 Resolver Rule with the AWS Organization (true/false)"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name"
  type        = string
  default     = ""
}

variable "resolver_endpoint_id" {
  description = "Resolver Endpoint ID"
  type        = string
  default     = null
}

variable "rule_type" {
  description = "Rule Type (FORWARD|SYSTEM|RECURSIVE)"
  type        = string
  default     = "FORWARD"
}

variable "target_ip" {
  description = "Target IP (ex: 127.0.0.1:53)"
  type        = list(any)
  default     = []
}
