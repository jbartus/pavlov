how to deploy & run on amazon linux 2
```
sudo amazon-linux-extras install docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user
vi token.txt
cat token.txt | docker login https://docker.pkg.github.com -u jbartus --password-stdin
docker pull docker.pkg.github.com/jbartus/pavlov/pavlov:latest
docker run -d -p 7777:7777/udp -p 8177:8177/udp --name=pavlov docker.pkg.github.com/jbartus/pavlov/pavlov:latest
```
