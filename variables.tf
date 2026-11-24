variable "project_id" {
  description = "ID проекта из console.cloud.ru"
  type        = string
  default     = ""
}

variable "auth_key_id" {
  description = "ID ключа сервисного аккаунта"
  type        = string
  default     = ""
}

variable "auth_secret" {
  description = "Secret ключа сервисного аккаунта"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vpc_id" {
  description = "ID VPC"
  type        = string
  default     = ""
}

variable "my_ip_cidr" {
  description = "Ваш внешний IP для SSH, формат x.x.x.x/32"
  type        = string
  default     = "0.0.0.0/32"
}

variable "zone" {
  type    = string
  default = "ru.AZ-1"
}

variable "flavor" {
  description = "Конфигурация ВМ (CPU/RAM)"
  type        = string
  default     = "gen-1-1"
}

variable "disk_size" {
  description = "Размер диска в ГБ (по заданию — 15)"
  type        = number
  default     = 15
}
