output "artifact_bucket_name" {
  description = "S3 bucket storing versioned pipeline artifacts + source zip"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifact_bucket_arn" {
  description = "ARN of the artifact bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "source_object_key" {
  description = "S3 object key the pipeline polls for source changes"
  value       = var.source_object_key
}

output "pipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.main.name
}

output "build_project_name" {
  description = "CodeBuild project name for Build stage"
  value       = aws_codebuild_project.build.name
}

output "test_project_name" {
  description = "CodeBuild project name for Test stage"
  value       = aws_codebuild_project.test.name
}
