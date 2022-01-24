this repo is a co-mingle of
- a Dockerfile for building a pavlov container image
- a github action that does so, and pushes it to github packages
- a terraform script defining the aws infra to run the container

pushing/change litearlly anything will trigger a docker build, 
so then to deploy you need to delete the existing instance and
let the autoscale group replace it.  the userdata script will
pull and start the newly built image.

if there is no current instance, 'terraform apply' will get you
there
