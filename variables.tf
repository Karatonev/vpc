variable "region" {
  type        = string
  description = "AWS Region of operation"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of avaialability zones for deployment"
}

variable "vpc" {
  type = object({
    name          = string
    cidr          = string
    deploy_igw    = optional(bool, true)
    deploy_nat_gw = optional(bool, false)
    tags          = optional(map(string), {})
  })
}

variable "subnets" {
  type = map(object({
    name     = string
    type     = string
    internet = optional(bool, false) //If true var.natgw.deploy must be also set to true. No internet will be possible in private networks without deploying NAT GW.
    cidr     = string
    az       = optional(string)
    tags     = optional(map(string), {})
  }))
}

variable "natgw" {
  type = object({
    deploy  = bool
    subnets = list(string)
  })
}