import json
import boto3
import os

from fastapi import FastAPI
from pydantic import BaseModel, Field
from typing import Union
from mangum import Mangum
from dotenv import load_dotenv
from pathlib import Path

load_dotenv()

class PavlovServer(BaseModel):
    """
    This class is used to define the server's configuration.
    """
    bEnabled: bool = True
    ServerName: str = Field(min_length=5, max_length=35)
    MaxPlayers: int = Field(default=10, gt=0, lt=25)
    ApiKey: Union[str, None] = None
    bSecured: bool = True
    bCustomServer: bool = True
    bVerboseLogging: bool = False
    bCompetitive: bool = False
    bWhitelist: bool = False
    RefreshListTime: int = Field(default=120, gt=0)
    LimitedAmmoType: int = Field(default=0, lt=6)
    TickRate: int = Field(default=90, gt=29, lt=241)
    TimeLimit: int = Field(default=60)
    #Password=0000
    #BalanceTableURL="vankruptgames/BalancingTable/main"
    #MapRotation=(MapId="sand", GameMode="DM")

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.post("/pavlov-server")
def run_pavlov_server(pavlov_server: PavlovServer):

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

handler = Mangum(app, lifespan="off")