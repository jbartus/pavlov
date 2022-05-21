from pydantic import BaseModel, Field
from typing import Union

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