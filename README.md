# Microservices with Redis

This project shows how you can modernize a legacy application that use RDBMS with Redis.

* Caching: take some data out of RDBMS
* Use RediSearch to index relational data and provides autocomplete feature
* Use Redis Graph to provide a new way to navigate and use the data
* Build an event based architecture using Redis Streams


## 1- [Cache Invalidation](cache-invalidator-service)

This Spring Boot Application is a service that use Debezium in an embedded mode and listen to CDC event from MySQL.
Depending of the configuration, the table content is automatically cached as a hash or just invalidated based on the table primary key.




## Build and Run with Docker
### Run Locally

If you want to use the Web Service cache demo that call the OMDB API you must:

1. Generate a key here: [http://www.omdbapi.com/](http://www.omdbapi.com/) (do not forge to activate it, you will receive an email to which you must respond!)

2. When the application is ready go to the "Services" page and enter the key in the configuration screen, this will save the key in a Redis Hash (lool at `ms:config` during the demo)


```
$ mvn clean package

$ docker-compose up --build

```

Cleanup

```

$ docker-compose down -v --rmi local --remove-orphans

```

### Publish CloudFormation template using ECS
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

You can now use the following link to launch the ECS cluster with the associated services:

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?stackName=aws-cfn&templateURL=https://s3.amazonaws.com/aws-workshop-cfn.redislabs.com/cfn.json"><img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"></a>
