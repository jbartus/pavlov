noop

aws launchconfig userdata
```
#!/bin/bash
yum update -y
yum install jq -y
amazon-linux-extras install docker
systemctl start docker
TOKEN=$(aws secretsmanager get-secret-value --secret-id github-pat-for-docker-pull --region us-east-2 | jq '.SecretString | fromjson | .GH_PAT' -r)
docker login https://docker.pkg.github.com -u jbartus --password $TOKEN
docker pull docker.pkg.github.com/jbartus/pavlov/pavlov:latest
docker run -d -p 7777:7777/udp -p 8177:8177/udp -p 9100:9100/tcp --name=pavlov docker.pkg.github.com/jbartus/pavlov/pavlov:latest
```

how to deploy & run on amazon linux 2
```
sudo amazon-linux-extras install docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user
exit
<log back in>
vi token.txt
cat token.txt | docker login https://docker.pkg.github.com -u jbartus --password-stdin
docker pull docker.pkg.github.com/jbartus/pavlov/pavlov:latest
docker run -d -p 7777:7777/udp -p 8177:8177/udp --name=pavlov docker.pkg.github.com/jbartus/pavlov/pavlov:latest
```

how to deplly & run on debian 10
```
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo usermod -a -G docker $(whoami)
exit
<log back in>
vi token.txt
cat token.txt | docker login https://docker.pkg.github.com -u jbartus --password-stdin
docker pull docker.pkg.github.com/jbartus/pavlov/pavlov:latest
docker run -d -p 7777:7777/udp -p 8177:8177/udp --name=pavlov docker.pkg.github.com/jbartus/pavlov/pavlov:latest
```
