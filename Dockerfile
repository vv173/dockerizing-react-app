# syntax=docker/dockerfile:1

# ======== etap1 ==== budowanie aplikacji =================
# ======== budowa aplikacji w kontenerze roboczym =========
FROM scratch as builder

# Docker na podstawie architektury hosta pobiera obraz alpine o tej samej architekturze
# BUILDARCH jest częścią zestawu automatycznie zdefiniowanych argumentów kompilacji.
# Zawsze zawiera w sobie architekturę bieżącego systemu.
ARG BUILDARCH
ADD ./build_os/alpine-minirootfs-3.18.0-${BUILDARCH}.tar.gz /
# Argumenty PORT oraz NAME potrzebne są do generacji logów.
# Argument USER_ID jest używany jako id usera
ARG PORT
ARG NAME
ARG USER_ID=3333
# uaktualnienie systemu w warstwie bazowej,
# instalacja niezbędnych komponentów środowiska roboczego
# oraz usunięcie cache
RUN apk update && \
    apk upgrade && \
    apk add --no-cache nodejs=18.16.0-r1 \
    npm=9.6.6-r0 \
    openssh-client \
    git && \
    rm -rf /etc/apk/cache
# Dobrą praktyką jest uruchomienie aplikacja z poziumu użytkownika o mniejszych uprawnieniach, niż root.
RUN addgroup --gid $USER_ID -S node && \
    adduser --uid $USER_ID -S node -G node
# Zmiana bieżącego użytkownika z root na node
USER node
# Do budowania kontenera skorzystałem z opcji --ssh,
# aby mieć dostęp do socketu ssh hosta.
# Następnie wyszukujemy wszystkie kluczę związanę z github
# i dodajemy ich do kluczów znanych
RUN mkdir -p -m 0700 ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts
# Zmiana katalogu bieżącego
WORKDIR /home/node/app
# Ten typ montowania umożliwia dostęp do kluczy SSH poprzez agenta SSH.
# Za pomocą klucza ssh pobieramy repo
RUN --mount=type=ssh,uid=$USER_ID,gid=$USER_ID \
    git clone git@github.com:vv173/dockerizing-react-app.git .
# Ten typ montowania pozwala na przechowywanie (cache) katalogów używanych przez kompilatory i menedżery pakietów.
# Instalacji zależności.
# Polecenie npm ci gwarantuje czystą i powtarzalną instalację zależności,
# polegając wyłącznie na pliku blokady, zapewniając spójne kompilacje.
RUN --mount=id=npm-cache,type=cache,sharing=locked,target=/home/node/.npm,uid=$USER_ID,gid=$USER_ID \
    npm ci --omit=dev
# Budowanie zoptymalizowanej wersji produkcyjnej
RUN npm run build --port=${PORT:-80} --name="${NAME:-'Viktor Vodnev'}"

# ========= etap2 ==== produkcyjny =================
# ========= budowa produkcyjnego kontenera =========
FROM nginx:1.24.0-alpine3.17-slim
# Argument PORT ustawia wartość portu na którym nasłuchiwa serwer NGINX.
# Argument NAME ustawia imie i nazwisko w labelu kontenera.
ARG PORT
ARG NAME
# Data i czas w formacie RFC 3339
ARG DATE="2023-12-05T23:06:00.000Z"
# OCI labels
LABEL "org.opencontainers.image.created"="${DATE}"
LABEL "org.opencontainers.image.authors"="${NAME}"
LABEL "org.opencontainers.image.url"="https://hub.docker.com/r/v17v3/zad1"
LABEL "org.opencontainers.image.source"="https://github.com/vv173/dockerizing-react-app"
LABEL "org.opencontainers.image.documentation"="https://github.com/vv173/dockerizing-react-app/blob/main/README.md"
LABEL "org.opencontainers.image.title"="Zadanie 1"
# Deklaracja zmienncyh srodowiskowych
ENV PORT=$PORT
ENV NODE_ENV=production
# uaktualnienie systemu w warstwie produkcyjnej,
# instalacja niezbędnych komponentów środowiska
RUN apk add --update --force-overwrite --no-cache \
    curl=8.1.0-r0 \
    openssl=3.0.8-r4 \
    libssl3=3.0.8-r4 \
    libcrypto3=3.0.8-r4
# kopiowanie konfiguracji serwera HTTP dla srodowiska produkcyjnego
COPY --link --from=builder /home/node/app/nginx.conf /etc/nginx/conf.d/default.conf
# kopiowanie aplikacji dla serwera HTTP
COPY --link --from=builder /home/node/app/build /usr/share/nginx/html
COPY --link --from=builder /home/node/app/zad1.log /var/log/zad1.log
# Zmiana portu w konfiguracji nginx
RUN sed -i "s/listen 80;/listen $PORT;/g" /etc/nginx/conf.d/default.conf
# deklaracja portu aplikacji w kontenerze 
EXPOSE $PORT
# monitorowanie dostepnosci serwera 
HEALTHCHECK --interval=4s --timeout=20s --start-period=2s --retries=3 \
    CMD curl -f http://localhost:${PORT}/ || exit 1
# deklaracja sposobu uruchomienia serwera
ENTRYPOINT ["nginx", "-g", "daemon off;"]