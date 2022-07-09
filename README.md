this repo is a co-mingle of
- a Dockerfile for building a pavlov container image
- a github action that does so, and pushes it to github packages
- a terraform script defining the aws infra to run a lambda
- a fastapi based python rest api for launching pavlov servers on ec2 to run in that lambda

the api can run locally with: `uvicorn index:app --reload`

packaging up the lambda for deployment:
```
cd .venv/lib/python3.9/site-packages && zip -r ../../../../package.zip . && cd - && zip -g package.zip *.py && zip -g package.zip userdata.sh
```
deploying:
```
terraform apply
```

you can then go to the function url returned by terraform in your browser and add `/docs` to the end to load the swagger-ui

from there posting to /pavlov-server with the right body params will
-  launch an ec2 instance 
- that runs the userdata script 
- to setup docker 
- and 'template' out the game.ini file
- and then run the docker container with the config file mounted as a volume

the included Game.ini file is not used automatically, you can use it to craft a json value with:
```
jq -Rs '.' Game.ini
```

when testing the api locally the code looks for env vars that would have been passed in lambda in the .env file
after terraform has been run once you can populated it with this command:
```
terraform output -json | jq '.["env-vars"].value[][] | to_entries[] | .key, "=\"", .value, "\"\n"' -j > .env
```
