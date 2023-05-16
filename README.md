## Build:

```
buildctl build \
    --frontend=dockerfile.v0 \
    --local context=. \
    --local dockerfile=. \
    --output type=image,name=docker.io/v17v3/zad1,push=true \
    --ssh default=$SSH_AUTH_SOCK \
    --export-cache type=registry,ref=docker.io/v17v3/zad1-cache \
    --import-cache type=registry,ref=docker.io/v17v3/zad1-cache \
    --opt build-arg:USER_ID=7777 \
    --opt build-arg:NAME='User Name' \
    --opt build-arg:PORT=8080 \
    --opt build-arg:DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

## Inspect labels

```
docker image inspect --format='{{json .Config.Labels}} docker.io/v17v3/zad1' 
```