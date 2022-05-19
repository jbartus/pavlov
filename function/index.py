import json
import boto3
import os

from fastapi import FastAPI
from mangum import Mangum

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.post("/foo")
def run_foo(name: str):
    userdata1 = '''#!/bin/bash
yum update -y
yum install jq -y
amazon-linux-extras install docker
systemctl start docker
TOKEN=$(aws secretsmanager get-secret-value --secret-id github-pat-for-docker-pull --region us-east-2 | jq '.SecretString | fromjson | .GH_PAT' -r)
docker login https://docker.pkg.github.com -u jbartus --password $TOKEN
docker pull docker.pkg.github.com/jbartus/pavlov/pavlov:latest
cat<<EOT > /tmp/Game.ini
[/Script/Pavlov.DedicatedServer]
bEnabled=true
ServerName="'''
    userdata2 = '''"
MaxPlayers=16
bSecured=true
bCustomServer=true
bWhitelist=false
RefreshListTime=120
LimitedAmmoType=0
TickRate=100
TimeLimit=60
MapRotation=(MapId="UGC1664873782", GameMode="SND") # dust ii
MapRotation=(MapId="UGC1080743206", GameMode="SND") # office
MapRotation=(MapId="UGC2744233926", GameMode="SND") # mirage
MapRotation=(MapId="UGC1695916905", GameMode="SND") # cache
MapRotation=(MapId="UGC1661039078", GameMode="SND") # inferno
MapRotation=(MapId="UGC1676961583", GameMode="SND") # overpass
EOT
docker run \
-d \
-p 7777:7777/udp \
-p 8177:8177/udp \
-p 9100:9100/tcp \
-v /tmp/Game.ini:/home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer/Game.ini \
--name=pavlov docker.pkg.github.com/jbartus/pavlov/pavlov:latest
'''

    ec2 = boto3.client('ec2')

    ec2.run_instances(
        ImageId=os.environ.get('AMZN2AMI'),
        MinCount=1,
        MaxCount=1,
        InstanceType='m6a.large',
        SecurityGroupIds=[os.environ.get('SECGRPID')],
        KeyName='ohio-pavlov',
        IamInstanceProfile={'Arn': os.environ.get('INSTPROF')},
        UserData=userdata1 + name + userdata2,
        BlockDeviceMappings=[
            {
                'DeviceName': '/dev/xvda',
                'Ebs': {
                    'VolumeSize': 100
                }
            }
        ],
        InstanceMarketOptions={'MarketType': 'spot'}
    )

    return {"servername": name }

handler = Mangum(app, lifespan="off")