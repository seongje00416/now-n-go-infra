output "jenkins_public_ip" {
  description = "Jenkins 서버 퍼블릭 IP (EIP)"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_ui_url" {
  description = "Jenkins UI 접속 URL"
  value       = "http://${aws_eip.jenkins.public_ip}:8000"
}

output "registry_url" {
  description = "Local Docker Registry URL"
  value       = "${aws_eip.jenkins.public_ip}:5000"
}

output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "ssh -i <your-private-key> ubuntu@${aws_eip.jenkins.public_ip}"
}