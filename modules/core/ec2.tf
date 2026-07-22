# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# EC2
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
resource "aws_key_pair" "ansible" {
  count = var.create_operational_baseline ? 1 : 0

  key_name   = "${var.prefix}-ansible-key"
  public_key = var.ssh_public_key

  lifecycle {
    precondition {
      condition     = var.ssh_public_key != null && trimspace(var.ssh_public_key) != ""
      error_message = "ssh_public_key must be set when create_operational_baseline is true."
    }
  }
}
