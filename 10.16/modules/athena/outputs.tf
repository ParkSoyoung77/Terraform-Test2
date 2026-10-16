output "workgroup_name" {
  value = aws_athena_workgroup.this.name
}

output "database_name" {
  value = aws_glue_catalog_database.this.name
}

output "table_name" {
  value = aws_glue_catalog_table.cloudtrail.name
}