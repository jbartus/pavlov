import json
import boto3
import os

from fastapi import FastAPI
from mangum import Mangum
from dotenv import load_dotenv
from pathlib import Path
from models import PavlovServer

load_dotenv()

app = FastAPI()

@app.get("/")
async def read_root():
    return {"Hello": "World"}

@app.post("/pavlov-server")
async def run_pavlov_server(pavlov_server: PavlovServer):

    userdata = Path('userdata.sh').read_text()

    gameini1 = '''
cat <<EOT > /tmp/Game.ini
[/Script/Pavlov.DedicatedServer]
bEnabled=true
ServerName="'''
    gameini2 = '''"
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
'''
    dockerun = '''docker run \
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
        UserData=userdata + gameini1 + pavlov_server.ServerName + gameini2 + dockerun,
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

    return pavlov_server

handler = Mangum(app)