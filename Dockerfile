# syntax=docker/dockerfile:1
FROM scratch as builder

ADD alpine-minirootfs-3.18.0-x86_64.tar.gz /

ARG PORT
ARG NAME
ARG USER_ID=3333

RUN apk update && \
    apk upgrade && \
    apk add --no-cache nodejs=18.16.0-r1 \
    npm=9.6.6-r0 \
    openssh-client \
    git && \
    rm -rf /etc/apk/cache

RUN addgroup --gid $USER_ID -S node && \
    adduser --uid $USER_ID -S node -G node

USER node

RUN mkdir -p -m 0700 ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

WORKDIR /home/node/app

RUN --mount=type=ssh,uid=$USER_ID,gid=$USER_ID git clone git@github.com:vv173/dockerizing-react-app.git .

# Add args
# Install node dependencies
# Explain in the comments why `npm ci` is better then npm install
RUN npm ci

# Create an optimized production build
RUN npm run build --port=${PORT:-80} --name="${NAME:-'Viktor Vodnev'}"



FROM nginx:1.24.0-alpine3.17-slim

ARG PORT
ARG NAME
# Data i czas w formacie RFC 3339
ARG DATE="2023-12-05T23:06:00.000Z"

LABEL "org.opencontainers.image.created"="${DATE}"
LABEL "org.opencontainers.image.authors"="Viktor Vodnev"
LABEL "org.opencontainers.image.url"="https://hub.docker.com/r/v17v3/zad1"
LABEL "org.opencontainers.image.source"="https://github.com/vv173/dockerizing-react-app"
LABEL "org.opencontainers.image.documentation"="https://github.com/vv173/dockerizing-react-app/blob/main/README.md"
LABEL "org.opencontainers.image.title"="Zadanie 1"

ENV PORT=$PORT
ENV NODE_ENV=production

# ???
RUN apk add --update --no-cache curl

COPY --link --from=builder /home/node/app/nginx.conf /etc/nginx/conf.d/default.conf
COPY --link --from=builder /home/node/app/build /usr/share/nginx/html
COPY --link --from=builder /home/node/app/zad1.log /var/log/zad1.log

RUN sed -i "s/listen 80;/listen $PORT;/g" /etc/nginx/conf.d/default.conf

EXPOSE $PORT

HEALTHCHECK --interval=4s --timeout=20s --start-period=2s --retries=3 \
    CMD curl -f http://localhost:${PORT}/ || exit 1

ENTRYPOINT ["nginx", "-g", "daemon off;"]