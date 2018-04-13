# Memcached Container Image 

This code is based on : https://github.com/docker-library/memcached 

This container image uses a bash entrypoint script : scripts/docker-entrypoint.sh

# Usage

The makefile contains a number of variables including which version of Memcached to install and registry/repo/image variables.
Please review these variables to ensure you understand the purpose of each. 

## Build the Memcached image 
```
make build
```

## Start Memcached 
```
make start
```


## Test Memcached

```
make test

Example output :

```

## Cleanup

This will remove the memcached container and image from the previous steps.
```
make clean
```
