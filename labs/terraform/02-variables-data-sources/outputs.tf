
output "generated_file_path" {
  description = "Path of the generated note."
  value       = local_file.project_note.filename
}

output "file_content_read_back" {
  description = "Content read from the generated note."
  value       = data.local_file.read_back.content
}
