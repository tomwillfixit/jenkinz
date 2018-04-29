# Makefile used to create Memcached image for dev and test purposes

############################
### Section 1 
############################
AUTHOR := "tomwillfixit"
REPO := memcached
IMAGE_NAME := memcached
MEMCACHED_VERSION := 1.5.4
MEMCACHED_SHA1 := 29cb75cc234dbaceed6e89db029af8363706f0fe
EXPOSED_PORT := 11211

############################
### Section 2
############################

build:
	export SHA=$(shell git log -1 --pretty=format:%h) ; \
	export BRANCH=$(shell git symbolic-ref --short HEAD) ; \
	docker build --no-cache\
		-t ${REPO}/${IMAGE_NAME}:${MEMCACHED_VERSION} \
		--build-arg AUTHOR=${AUTHOR} \
		--build-arg MEMCACHED_VERSION=${MEMCACHED_VERSION} \
		--build-arg MEMCACHED_SHA1=${MEMCACHED_SHA1} \
		--build-arg GIT_SHA=$${SHA} \
		--build-arg GIT_BRANCH=$${BRANCH} \
		.
	echo "Image Labels"
	docker inspect ${REPO}/${IMAGE_NAME}:${MEMCACHED_VERSION} |jq -r '.[0].Config.Labels'
start:
	docker run -d \
		-p ${EXPOSED_PORT}:${EXPOSED_PORT} \
		--name memcached \
		${REPO}/${IMAGE_NAME}:${MEMCACHED_VERSION} 

logs:
	docker logs -f memcached 

test:
	echo "Starting Test : connectivity_check.sh"
	./connectivity_check.sh ${REPO}/${IMAGE_NAME}:${MEMCACHED_VERSION} ${MEMCACHED_IMAGE}

clean:
	docker rm -f memcached || true
	docker rmi -f ${REPO}/${IMAGE_NAME}:${MEMCACHED_VERSION} ${MEMCACHED_IMAGE}

quickcheck:
	docker run --rm alpine:3.7 echo quickcheck

