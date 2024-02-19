## CZĘŚĆ I
<br/><br/>
### a. Zbudowanie kontenera
Budowanie odbywa się za pomocą silnika buildkit. Przed budowaniem należy uruchomić kontener buildkit oraz dodać zmienną środowiskową zawierającą scieżkę do kontenera buildkit.   
```
docker run -d --name buildkitd --restart always --privileged moby/buildkit:latest
export BUILDKIT_HOST=docker-container://buildkitd
```
Oprócz tego kontener wymaga dostępność agenta ssh, więc przed budowaniem należy upewnić się, że jest on włączony.
```
eval $(ssh-agent)
```
Poza tym należy pamiętać, że agent ssh powinien zawierać w sobie klucz do github. Sprawdzić czy klucz został dodany, można używając polecenia:
```
ssh-add -L
```
Pod czas budowanie cache obrazu jest osobno exportowany do docker hub. Obraz kontenera jest przekazywany do dwóch registry, dockerhub oraz azure.
<br/><br/>
Budowanie kontenera przy użyciu polecenia buildctl.
```
buildctl build \
    --frontend=dockerfile.v0 \
    --local context=. \
    --local dockerfile=. \
    --ssh default=$SSH_AUTH_SOCK \
    --output type=image,\"name=zad1registry.azurecr.io/zad1,docker.io/v17v3/zad1\",push=true \
    --export-cache type=registry,mode=max,ref=docker.io/v17v3/zad1-cache \
    --import-cache type=registry,ref=docker.io/v17v3/zad1-cache \
    --opt build-arg:USER_ID=7777 \
    --opt build-arg:NAME='Viktor Vodnev' \
    --opt build-arg:PORT=8080 \
    --opt build-arg:DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --opt platform=linux/arm/v7,linux/arm64/v8,linux/amd64
```
<br/><br/>
Budowanie kontenera przy użyciu polecenia docker buildx.
```
docker buildx build \
    --ssh default=$SSH_AUTH_SOCK \
    --cache-from type=registry,ref=docker.io/v17v3/zad1-cache \
    --cache-to type=registry,ref=docker.io/v17v3/zad1-cache \
    --output=type=registry \
    --platform=linux/arm/v7,linux/arm64/v8,linux/amd64 \
    --build-arg USER_ID=7777 \
    --build-arg NAME='Viktor Vodnev' \
    --build-arg PORT=8080 \
    --build-arg DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --progress=tty \
    --tag docker.io/v17v3/zad1 \
    --tag zad1registry.azurecr.io/zad1 .
```
### b. Uruchomienie kontenera.
```
docker run --name zad1 -dt -p 8080:8080 docker.io/v17v3/zad1
```
### c. Uzyskanie logów wygenerowanych przez aplikacje.
Plik wygenerowany przez aplikacje znajduje się w katalogie /var/log o nazwie zad1.log.
```
docker exec zad1 cat /var/log/zad1.log
```
![](./screenshots/logs.png)
### d. Warstwy kontenera.
Podejrzeć zbudowane warstwa oraz ich hash możemy używ polecenia **docker inspect**
```
docker inspect docker.io/v17v3/zad1 | jq '.[].RootFS.Layers'
```
![](./screenshots/layers.png)

Aby policzyć warstwy kontenera należy dodać opcje 'length' do polecenia **jq**
```
docker inspect docker.io/v17v3/zad1 | jq '.[].RootFS.Layers | length'
```
Dodatkowo utworzone warstwy kontenera możemy sprawdzić w aplikacji Dive.
![](./screenshots/dive.png)


## Skanowanie obrazu kontenera za pomocą narzędzia Docker Scount.

![](./screenshots/scout.png)

Dodatkowo raporty w formacie plików tekstowych json zostali umieszczone w folderze scout_reports.

## Skanowanie obrazu kontenera za pomocą narzędzia Snyk.
![](./screenshots/snyk.png)

## CZĘŚĆ II

Aby zbudować obraz kontenera wykorzystując sterownik docker-container, należy utworzyć instancje buildx typu docker-container. W moim przypadku utworzyłem instancje buildx o dwóch węzłach. Pierwszy jest utworzony lokalnie, drugi na środowisku chmurowym w Azure. Builder o dwóch węzłach znacznie zmniejsza czas budowania obrazów wieloplatformowych.

1\) Tworzenie buildera z węzłem w środowisku chmurowym Azure.
```
docker buildx create \
    --name zad1-builder \
    --driver docker-container \
    --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
    --use ssh://azureuser@zad1-builder.northeurope.cloudapp.azure.com
```
2\) Tworzenie i podpięcie węzła stworzonego lokalnie do buildera.
```
docker buildx create \
    --name zad1-builder \
    --append \
    --driver docker-container \
    --platform linux/arm/v7,linux/arm64/v8,linux/amd64
```
3\) Uruchomienie buildera oraz sprawdzenie poprawności utworzonych węzłów. 
```
docker buildx inspect --bootstrap --builder zad1-builder
```
4\) Następnie możemy zbudować obraz używając polecenia do budowania z części I
5\) Sprawdzić, czy obraz został zbudowany dla wszystkich podanych platform, można używając polecenie:
```
docker manifest inspect docker.io/v17v3/zad1
```
![](./screenshots/manifest.png)

Pobieranie kodu bezpośrednio z github wewnątrz kontenera jest rozwiązane poprzez użycie RUN --mount=type=ssh w Dockerfile, ta opcja umożliwia dostęp do kluczy SSH za pośrednictwem agentów SSH. Dlatego warto upewnić się, że ssh agent jest uruchomiony.

Kwestia cache’u została rozwiązana za pomocą opcji RUN --mount=type=cache, jest to montowanie cache’u, który będzie przechowywany pomiędzy budowaniem obrazów.