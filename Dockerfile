FROM scratch as builder
ADD alpine-minirootfs-3.18.0-x86_64.tar.gz /

ARG PORT
ARG NAME

RUN apk update && \
    apk upgrade && \
    apk add --no-cache nodejs=18.16.0-r1 \
    npm=9.6.6-r0 && \
    rm -rf /etc/apk/cache

RUN addgroup -S node && \
    adduser -S node -G node

USER node
WORKDIR /home/node/app

# Add args
COPY --chown=node:node log ./log
COPY --chown=node:node src ./src
COPY --chown=node:node public ./public
COPY --chown=node:node ./package*.json .

RUN npm install

RUN npm run build --port=${PORT:-80} --name="${NAME:-'Viktor Vodnev'}"



FROM nginx:1.24.0-alpine3.17-slim

ARG PORT
ARG NAME

ENV PORT=$PORT

# ???
RUN apk add --update --no-cache curl

COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /home/node/app/build /usr/share/nginx/html
COPY --from=builder /home/node/app/zad1.log /var/log/zad1.log

RUN sed -i "s/listen 80;/listen $PORT;/g" /etc/nginx/conf.d/default.conf

EXPOSE $PORT

HEALTHCHECK --interval=4s --timeout=20s --start-period=2s --retries=3 \
    CMD curl -f http://localhost:${PORT}/ || exit 1

ENTRYPOINT ["nginx", "-g", "daemon off;"]