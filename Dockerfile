# syntax=docker/dockerfile:1
FROM scratch as builder
ADD alpine-minirootfs-3.18.0-x86_64.tar.gz /

ARG PORT
ARG NAME
ARG ID=3333

RUN apk update && \
    apk upgrade && \
    apk add --no-cache nodejs=18.16.0-r1 \
    npm=9.6.6-r0 \
    openssh-client \
    git && \
    rm -rf /etc/apk/cache

RUN addgroup --gid $ID -S node && \
    adduser --uid $ID -S node -G node

USER node

RUN mkdir -p -m 0700 ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

WORKDIR /home/node/app

RUN --mount=type=ssh,uid=$ID,gid=$ID git clone git@github.com:vv173/dockerizing-react-app.git .

# Add args
# Install node dependencies
RUN npm install

# Create an optimized production build
RUN npm run build --port=${PORT:-80} --name="${NAME:-'Viktor Vodnev'}"



FROM nginx:1.24.0-alpine3.17-slim

ARG PORT
ARG NAME

ENV PORT=$PORT

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