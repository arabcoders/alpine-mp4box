FROM alpine:latest AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apk add --update git coreutils curl gcc g++ musl-dev libffi-dev openssl-dev make 

WORKDIR /tmp
RUN mkdir /gpac-master && curl -k -L https://github.com/gpac/gpac/archive/refs/tags/v2.4.0.zip -o /tmp/gpac.zip && \
  unzip /tmp/gpac.zip && mv /tmp/gpac-*/* /gpac-master

WORKDIR /gpac-master
RUN ./configure --static-bin --use-zlib=no && make -j4

FROM debian:bookworm-slim AS bento4_builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y --no-install-recommends ca-certificates cmake g++ git make && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch v1.6.0-641 https://github.com/axiomatic-systems/Bento4.git . && \
  test "$(git rev-parse HEAD)" = "dc264854d1f76c370b65b18d9f303a95f7f21ab1"

# GCC does not recognize initialization through AP4_SetMemory in this padding path.
RUN sed -i 's/AP4_UI08 pad\[15\];/AP4_UI08 pad[15] = {0};/' Source/C++/Core/Ap4RtpHint.cpp && \
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
  -DCMAKE_EXE_LINKER_FLAGS=-static && \
  cmake --build build --target mp4decrypt --parallel 2 && \
  strip build/mp4decrypt && \
  tar --exclude=.git --exclude=build -czf /tmp/source.tar.gz .

FROM alpine:latest

ARG TZ=UTC

VOLUME /work

WORKDIR /work

COPY --from=builder /gpac-master/bin/gcc/MP4Box /usr/bin/mp4box
COPY --from=bento4_builder /src/build/mp4decrypt /usr/bin/mp4decrypt
COPY --from=bento4_builder /src/Documents/LICENSE.txt /usr/share/doc/bento4/LICENSE.txt
COPY --from=bento4_builder /tmp/source.tar.gz /usr/share/doc/bento4/source.tar.gz

RUN chmod +x /usr/bin/mp4box /usr/bin/mp4decrypt

ENTRYPOINT ["/usr/bin/mp4box"]
