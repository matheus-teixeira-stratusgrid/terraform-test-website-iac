module "mywebsite" {
  source      = "../s3-static-website"
  endpoint    = "matheus-teixeira-stratusgrid-static-website-test"
  region      = var.region
  bucket_name = "matheus-teixeira-stratusgrid-static-website-test"
  env_name    = "dev"
  source_repo = "matheus-teixeira-stratusgrid/terraform-test-website-iac"
  developer   = "Matheus Teixeira"
}
