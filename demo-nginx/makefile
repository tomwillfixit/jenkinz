# Makefile used to build nginx

############################
### Section 1 
############################
AUTHOR := "tomwillfixit"
REPO := nginx
IMAGE_NAME := nginx
NGINX_VERSION := 1.5.4

############################
### Section 2
############################

build:
	docker build --no-cache\
		-t ${REPO}/${IMAGE_NAME}:${NGINX_VERSION} \
		--build-arg AUTHOR=${AUTHOR} \
		--build-arg NGINX_VERSION=${NGINX_VERSION} \
		.
	echo "Image Labels"
	docker inspect ${REPO}/${IMAGE_NAME}:${NGINX_VERSION} |jq -r '.[0].Config.Labels'

clean:
	docker rmi -f ${REPO}/${IMAGE_NAME}:${NGINX_VERSION} ${NGINX_IMAGE}

