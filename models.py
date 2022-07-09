from pydantic import BaseModel

class PavlovServer(BaseModel):
    """
    This class is used to define the server's configuration.
    """
    gameini: str