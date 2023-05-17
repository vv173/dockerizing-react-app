## Build:

```
buildctl build \
    --frontend=dockerfile.v0 \
    --local context=. \
    --local dockerfile=. \
    --output type=image,name=docker.io/v17v3/zad1,push=true \
    --ssh default=$SSH_AUTH_SOCK \
    --export-cache type=registry,mode=max,ref=docker.io/v17v3/zad1-cache \
    --import-cache type=registry,ref=docker.io/v17v3/zad1-cache \
    --opt build-arg:USER_ID=7777 \
    --opt build-arg:NAME='User Name' \
    --opt build-arg:PORT=8080 \
    --opt build-arg:DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --opt platform=linux/arm/v7,linux/arm64/v8,linux/amd64
```

```
docker buildx build \
    --cache-from type=registry,ref=docker.io/v17v3/zad1-cache \
    --cache-to type=registry,ref=docker.io/v17v3/zad1-cache \
    --output=type=registry \
    --ssh default=$SSH_AUTH_SOCK \
    --platform=linux/arm/v7,linux/arm64/v8,linux/amd64 \
    --build-arg USER_ID=7777 \
    --build-arg NAME='User Name' \
    --build-arg PORT=8080 \
    --build-arg DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --progress=tty \
    --tag docker.io/v17v3/zad1 .
```

## Create builder:

```
docker buildx create \
    --name zad1-builder \
    --bootstrap \
    --driver docker-container \
    --use \
    --platform linux/arm/v7,linux/arm64/v8,linux/amd64
```

## Inspect labels

```
docker image inspect --format='{{json .Config.Labels}} docker.io/v17v3/zad1' 
```