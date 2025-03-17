FROM alpine:latest AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apk add --update git coreutils curl gcc g++ musl-dev libffi-dev openssl-dev make 

WORKDIR /tmp
RUN mkdir /gpac-master && curl -k -L https://github.com/gpac/gpac/archive/refs/tags/v2.4.0.zip -o /tmp/gpac.zip && \
  unzip /tmp/gpac.zip && mv /tmp/gpac-*/* /gpac-master

WORKDIR /gpac-master
RUN ./configure --static-bin --use-zlib=no && make -j4

FROM alpine:latest

ARG TZ=UTC

VOLUME /work

WORKDIR /work

COPY --from=builder /gpac-master/bin/gcc/MP4Box /usr/bin/mp4box

RUN chmod +x /usr/bin/mp4box

ENTRYPOINT ["/usr/bin/mp4box"]
