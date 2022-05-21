#!/bin/bash
yum update -y
yum install jq -y
amazon-linux-extras install docker
systemctl start docker
TOKEN=$(aws secretsmanager get-secret-value --secret-id github-pat-for-docker-pull --region us-east-2 | jq '.SecretString | fromjson | .GH_PAT' -r)
docker login https://docker.pkg.github.com -u jbartus --password $TOKEN
docker pull docker.pkg.github.com/jbartus/pavlov/pavlov:latest
