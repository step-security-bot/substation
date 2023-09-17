variable config {
  type = object({
    name = string
    policy = optional(string, "")
  })
}

variable "tags" {
  type    = map(any)
  default = {}
}
