# 1. Create the Transit Gateway in the Management Account
resource "aws_ec2_transit_gateway" "hub" {
  description = "Main TGW connecting Shared Services, Prod, and Dev"
  auto_accept_shared_attachments = "enable" # Simplifies cross-account setup
}

# 2. Share TGW with the Organization or Specific Accounts via RAM
resource "aws_ram_resource_share" "tgw_share" {
  name                      = "tgw-share"
  allow_external_principals = false
}

resource "aws_ram_resource_association" "tgw_association" {
  resource_arn       = aws_ec2_transit_gateway.hub.arn
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}

# Associate Prod and Dev AWS Account IDs
resource "aws_ram_principal_association" "prod_dev" {
  for_each           = toset(["123456789012", "987654321098"]) # Replace with actual IDs
  principal          = each.value
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}

# 3. Create VPC Attachment (Executed in the Spoke/Prod Account)
resource "aws_ec2_transit_gateway_vpc_attachment" "prod_attachment" {
  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  vpc_id             = aws_vpc.prod_vpc.id
}
