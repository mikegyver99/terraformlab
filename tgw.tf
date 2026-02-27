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

# 1. Create the Custom TGW Route Tables
resource "aws_ec2_transit_gateway_route_table" "prod_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  tags = { Name = "Prod-TGW-RT" }
}

resource "aws_ec2_transit_gateway_route_table" "dev_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  tags = { Name = "Dev-TGW-RT" }
}

resource "aws_ec2_transit_gateway_route_table" "shared_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  tags = { Name = "Shared-Services-TGW-RT" }
}

# 2. Setup Associations (Who uses which table for lookups)
resource "aws_ec2_transit_gateway_route_table_association" "prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_rt.id
}

# 3. Setup Propagations (Which networks are visible to whom)
# Prod can see Shared Services
resource "aws_ec2_transit_gateway_route_table_propagation" "prod_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod_rt.id
}

# Dev can see Shared Services
resource "aws_ec2_transit_gateway_route_table_propagation" "dev_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.dev_rt.id
}

# Shared Services can see BOTH Prod and Dev
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_all" {
  for_each = toset([aws_ec2_transit_gateway_vpc_attachment.prod.id, aws_ec2_transit_gateway_vpc_attachment.dev.id])
  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_rt.id
}
