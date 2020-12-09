# Use the envar PUBLISH_LOCATION, if set.
# Must be an S3 url
PL=$(if $(PUBLISH_LOCATION), $(PUBLISH_LOCATION), s3://aws-workshop-cfn.redislabs.com)

# publish the cloudformation template, using whatever envars are set to get the credentials
# and region
publish: cfn.json
	docker run --rm -e AWS_PROFILE -e AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID -e AWS_REGION -v ${HOME}/.aws:/root/.aws -v ${PWD}:/src amazon/aws-cli s3 cp /src/$? $(PL)


# Create the final template. The jq_filter does several jobs. 
cfn.json: ecs.json jq_filter
	cat $< | docker run --rm -i -v ${PWD}:/src imega/jq -f /src/jq_filter >$@


# Create the intermediate json from the restricted ports version of the docker-compose.yaml
# This is necessary because the docker compose has a bug (https://github.com/docker/cli/issues/2850) so converting to yaml and then to json is the way to go
ecs.json: docker-compose-restricted-ports.yml
	docker compose --context redislabs convert -f $< --format yaml | docker run --rm -i mikefarah/yq yq -j r --prettyPrint - >$@

# Remove ports that shouldn't be exposed. I'm doing this simply because I don't want
# to change the upstream definition of docker-compose.yml
docker-compose-restricted-ports.yml: docker-compose.yml
	cat $< | \
	docker run --rm -i mikefarah/yq yq d - 'services.*.ports(.==6*)' | \
	docker run --rm -i mikefarah/yq yq d - 'services.*.ports(.==3*)' | \
	docker run --rm -i mikefarah/yq yq d - 'services.*.ports(.==808*)' > $@

