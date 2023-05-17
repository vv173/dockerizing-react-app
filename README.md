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
docker build buildx \
    --cache-from type=registry,ref=docker.io/v17v3/zad1-cache \
    --cache-to type=registry,ref=docker.io/v17v3/zad1-cache \
    --ssh default=$SSH_AUTH_SOCK \
    --build-arg USER_ID=7777 \
    --build-arg NAME='User Name' \
    --build-arg PORT=8080 \
    --build-arg DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    --tag docker.io/v17v3/zad1 .
```

## Inspect labels

```
docker image inspect --format='{{json .Config.Labels}} docker.io/v17v3/zad1' 
```