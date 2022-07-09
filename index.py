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
    userdata += "\ncat <<EOT > /tmp/Game.ini\n" + pavlov_server.gameini + "EOT\n"
    userdata += "docker run -d -p 7777:7777/udp -p 8177:8177/udp -p 9100:9100/tcp"
    userdata += " -v /tmp/Game.ini:/home/steam/pavlovserver/Pavlov/Saved/Config/LinuxServer/Game.ini"
    userdata += " --name=pavlov docker.pkg.github.com/jbartus/pavlov/pavlov:latest"

    ec2 = boto3.client('ec2')

    ec2.run_instances(
        ImageId=os.environ.get('AMZN2AMI'),
        MinCount=1,
        MaxCount=1,
        InstanceType='m6a.large',
        SecurityGroupIds=[os.environ.get('SECGRPID')],
        KeyName='ohio-pavlov',
        IamInstanceProfile={'Arn': os.environ.get('INSTPROF')},
        UserData=userdata,
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