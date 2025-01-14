provider "mongodbatlas" {
  public_key  = var.public_key
  private_key = var.private_key
}

resource "mongodbatlas_project" "aws_atlas" {
  name   = "cbaird-new"
  org_id = var.atlasorgid
}
#########################################################################################
# resource "mongodbatlas_cluster" "cluster-atlas" {
#   project_id   = mongodbatlas_project.aws_atlas.id
#   name         = "cluster-atlas-terraformtest"
#   cluster_type = "REPLICASET"
#   replication_specs {
#     num_shards = 1
#     regions_config {
#       region_name     = "US_EAST_1"
#       # electable_nodes = 3
#       # priority        = 7
#       # read_only_nodes = 0
#     }
#   }
#   cloud_backup      = true
#   auto_scaling_disk_gb_enabled = true
#   mongo_db_major_version       = "5.0"

#   //Provider Settings "block"
#   provider_name               = "AWS"
#   disk_size_gb                = 10
#   provider_instance_size_name = "M10"
# }
#######################################################################################
##############dummy deleted part free account ###############################
resource "mongodbatlas_cluster" "cluster-atlas" {
  project_id                   = mongodbatlas_project.aws_atlas.id
  name                         = "tfncluster"
  cluster_type                 = "REPLICASET"
  backup_enabled               = false  # Backups not available for M0
  mongo_db_major_version       = "7.0"
  # provider_name              = "AWS"
  provider_name                = "TENANT"
  backing_provider_name        = "AWS"
  provider_region_name         = "US_EAST_1"
  provider_instance_size_name  = "M0"  # Free tier instance
  auto_scaling_disk_gb_enabled = false # Not applicable for M0
  disk_size_gb                 = 0.5   # Max for M0 is 2 GB
}
################################################################end of deleted part
//Creating the DB user + assigning permissions
resource "mongodbatlas_database_user" "db-user" {
  username           = var.atlas_dbuser
  password           = var.atlas_dbpassword
  auth_database_name = "admin"
  project_id         = mongodbatlas_project.aws_atlas.id
  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
  depends_on = [mongodbatlas_project.aws_atlas]
}
resource "mongodbatlas_network_container" "atlas_container" {
  atlas_cidr_block = var.atlas_vpc_cidr
  project_id       = mongodbatlas_project.aws_atlas.id
  provider_name    = "AWS"
  region_name      = var.atlas_region
}

data "mongodbatlas_network_container" "atlas_container" {
  container_id = mongodbatlas_network_container.atlas_container.container_id
  project_id   = mongodbatlas_project.aws_atlas.id
}

resource "mongodbatlas_network_peering" "aws-atlas" {
  accepter_region_name   = var.aws_region
  project_id             = mongodbatlas_project.aws_atlas.id
  container_id           = mongodbatlas_network_container.atlas_container.container_id
  provider_name          = "AWS"
  route_table_cidr_block = aws_vpc.primary.cidr_block
  vpc_id                 = aws_vpc.primary.id
  aws_account_id         = var.aws_account_id
}

resource "mongodbatlas_project_ip_access_list" "test" {
  project_id = mongodbatlas_project.aws_atlas.id
  cidr_block = aws_vpc.primary.cidr_block
  comment    = "cidr block for AWS VPC"
}