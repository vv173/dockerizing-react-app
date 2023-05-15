## Build:

```
buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. --output type=image,name=docker.io/v17v3/zad1,push=true --export-cache type=registry,ref=docker.io/v17v3/zad1-cache --import-cache type=registry,ref=docker.io/v17v3/zad1-cache
```