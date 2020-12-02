# ECS
## Running
You can run this system on [AWS ECS] and build it to run on ECS. This works by using a [Cloudformation] stack to build out the ECS cluster, and then you need to go to the URLs that are output from that stack.

You can use the following link to launch the ECS cluster with the associated services. It should take around 6-10 mins to deploy the stack. (Note that this **WILL NOT WORK** if launched in the `us-east-1` region. It hangs forever, for some reason):

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?stackName=aws-cfn&templateURL=https://s3.amazonaws.com/aws-workshop-cfn.redislabs.com/cfn.json"><img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"></a>

## Building (Developers only)
### Images
If you've changed the images then you need to build them and push them to the repository. 
This is far quicker to do if you do this on an AWS image and push from there, rather than push from your laptop.

### Build the images
```
mvn clean package &&
docker-compose build --force-rm --pull --parallel
```

### Authenticate to the public registry

```
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
```

### Push to the registry

```
docker-compose push
```

### Cloudformation Template
First, create an ECS context call `redislabs` (you'll only need to do this once):

```
docker context create ecs redislabs
```
(See the [official docs](https://docs.docker.com/engine/context/ecs-integration/#create-aws-context) for more details.)

Then use this context to convert the `docker-compose.yml` to a cloud-formation template (watch out - in this case there is NO hyphen between `docker` and `compose`!):

```
docker compose convert --context redislabs --format yaml |
docker run --rm -i -v "${PWD}":/workdir mikefarah/yq yq -j r --prettyPrint - > ecs.json
```
(This will likely given several warnings about unsupported attributes - don't worry about that!)

Finally, clean this up (replacing VPC and Subnet references with parameters) and publish a cloud formation template to `https://s3.amazonaws.com/aws-workshop.redislabs.com/cfn.json`

(If the `PUBLISH_LOCATION` envar is set then its value will be used as the publication location instead)

```
docker-compose -f dc.yml run publish_cfn
```
This uses the standard aws-cli techniques for finding the credentials so you might need to export either `AWS_PROFILE` or the `AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY` envars if you want to use anything but the assumed default profile.

(If you see: `upload failed: ./cfn.json to s3://aws-workshop.redislabs.com/cfn.json Unable to locate credentials` then you *definitely* need to do that export described above!)



----------
[AWS ECS]: https://aws.amazon.com/ecs/
[Cloudformation]: https://aws.amazon.com/cloudformation/
