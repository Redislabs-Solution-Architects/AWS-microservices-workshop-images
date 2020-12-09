# ECS
## Running
You can run this system on [AWS ECS]. This works by using a [Cloudformation] stack to build out the ECS cluster, using Docker images that have been pushed up to a public [Elastic Compute Repository (ECR)]. Once the stack has been created then you can go to the URLs that are output from that stack to access the servies.

You can use the following link to launch the ECS cluster with the associated services. It should take around 6-10 mins to deploy the stack. (Note that this **WILL NOT WORK** if launched in the `us-east-1` region. It hangs forever, for some reason):

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?stackName=aws-cfn&templateURL=https://s3.amazonaws.com/aws-workshop-cfn.redislabs.com/cfn.json"><MiG src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"></a>

## Building (Developers only)
### Prerequisites
We expect you to have:

- java
- maven
- docker
- docker-compose
- make

installed. 

### Overview
The image build process uses the `docker-compose.yml` file. Note that the ECR is hard-coded in there as `public.ecr.aws/i9l0l1r7`, which is owned by Redis Labs. As such you'll need to be a Redis Labs employee to push images to that repository.

### Images
The images
If you've changed the images then you need to build them and push them to the repository. 
This is far quicker to do if you do this on an AWS image and push from there, rather than push from your laptop.

#### Build the images
```
mvn clean package &&
docker-compose build --force-rm --pull --parallel
```

#### Pushing images to the public repository
First you must authenticate to the public registry

```
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
```
Then you can push the images to the actual repository:

```
docker-compose push
```

#### (Incomplete) Notes about Developing on an AWS image
I tried to do this using Cloud9 but couldn't configure the Docker storage properly. So I'm using an m5a.2xlarge instance (32GiB, 8CPU) running RHEL8 

I configured it thus:

```
# On RHEL 8
sudo dnf -y install java maven git python3-pip

## Docker from: https://linuxconfig.org/how-to-install-docker-in-rhel-8
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf -y install --nobest docker-ce
sudo systemctl disable firewalld
sudo systemctl enable --now docker

## docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

## awscli
sudo dnf -y install python3-pip
pip3 install awscli --upgrade --user

## Software
git clone https://github.com/TobyHFerguson/redis-microservices-demo.git
cd redis-microservices-demo/
mvn clean package && docker-compose build
```

### Cloudformation Template
NOTE - I could only get this to work on my Mac (Docker version
19.03.13, build 4484c46d9d) - using a RHEL 8 AWS image the docker
installed (Docker version 19.03.14, build 5eb3275d40) didn't support
creating an ECS context. I'm hoping this is a temporary bug!

First, create an ECS context call `redislabs` (you'll only need to do this once):

```
docker context create ecs redislabs
```
(See the [official docs](https://docs.docker.com/engine/context/ecs-integration/#create-aws-context) for more details.)

Then you can use `make` to do the work. In the following explanation the `UPPER CASE` values are envars which you might export before running `make`. The targets are:

- `publish`: publish the `cfn.json` file to the PUBLISH_LOCATION (defaults to `s3://aws-workshop-cfn.redislabs.com`) using any of the usual AWS credential finding techniques, so `AWS_PROFILE` or the `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` are available here

- `cfn.json`: create the `cfn.json` file from the `ecs.json` file, correcting the json on the way

- `ecs.json`: export the `ecs.json` file from the `docker-compose.yml`, using yaml to get the correct values, and then converting to json to further hack on the output.

(If you see: `upload failed: ./cfn.json to s3://aws-workshop.redislabs.com/cfn.json Unable to locate credentials` then you *definitely* need to do that export described above!)


----------
[AWS ECS]: https://aws.amazon.com/ecs/
[Cloudformation]: https://aws.amazon.com/cloudformation/
