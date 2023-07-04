FROM crystallang/crystal:1.6.2-alpine AS builder
RUN apk update && apk upgrade && apk add sqlite-static
WORKDIR /build/
ARG version

# RUN git clone --branch ${version:-dist} --depth 1 https://github.com/toddsundsted/ktistec .
COPY shard.yml shard.lock /build/
RUN shards install --production --jobs=12

COPY . /build/
RUN crystal build src/ktistec/server.cr --static --no-debug --release --stats --progress

FROM alpine:latest AS server
RUN apk --no-cache add tzdata
WORKDIR /app
COPY --from=builder /build/etc /app/etc
COPY --from=builder /build/public /app/public
COPY --from=builder /build/server /bin/server
RUN mkdir -p /data
RUN ln -s /app/public/uploads /data/uploads
ENV KTISTEC_DB=/data/ktistec.db
CMD ["/bin/server"]
VOLUME /data
EXPOSE 3000
