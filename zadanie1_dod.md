## CZĘŚĆ DODATKOWA

*4. Zbudować obrazy kontenera z aplikacją opracowaną w punkcie nr 1, które będą pracował na architekturach: linux/arm/v7, linux/arm64/v8 oraz linux/amd64 wykorzystując sterownik docker container. Dockerfile powinien wykorzystywać rozszerzony frontend, zawierać deklaracje  wykorzystania cache (jak w p.3) i umożliwiać bezpośrednie wykorzystanie kodów aplikacji umieszczonych w swoim repozytorium publicznym na GitHub.*

Aby zbudować obraz kontenera wykorzystując sterownik docker-container, należy utworzyć instancje buildx typu docker-container. W moim przypadku utworzyłem instancje buildx o dwóch węzłach. Pierwszy jest utworzony lokalnie, drugi na środowisku chmurowym w Azure. Builder o dwóch węzłach znacznie zmniejsza czas budowania obrazów wielu platformowych.

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
3\) Uruchomiamy buildera oraz sprawdzamy czy poprawnie zostali utworzone węzły. 
```
docker buildx inspect --bootstrap --builder zad1-builder
```
4\) Następnie możemy zbudować obraz używając polecenia do budowania z pliku zadanie1.md   
5\) Sprawdzić, czy obraz został zbudowany dla wszystkich podanych platform, można używając polecenie:
```
docker manifest inspect docker.io/v17v3/zad1
```
*screenshot*

Pobieranie kodu bezpośrednio z github wewnątrz kontenera jest rozwiązane poprzez użycie RUN --mount=type=ssh w Dockerfile, ta opcja umożliwia dostęp do kluczy SSH za pośrednictwem agentów SSH. Dlatego warto upewnić się, że ssh agent jest uruchomiony.

Kwestia cache’u została rozwiązana za pomocą opcji RUN --mount=type=cache, jest to montowanie cache’u, który będzie przechowywany pomiędzy budowaniem obrazów.