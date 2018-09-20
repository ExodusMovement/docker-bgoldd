FROM alpine:3.8 AS builder

ENV BUILD_TAG 0.15.2

RUN apk add --no-cache \
    autoconf \
    automake \
    boost-dev \
    build-base \
    openssl-dev \
    libevent-dev \
    libsodium-dev \
    libtool \
    zeromq-dev

RUN wget -O- https://github.com/BTCGPU/BTCGPU/archive/v$BUILD_TAG.tar.gz | tar xz && mv /BTCGPU-$BUILD_TAG /bgold
WORKDIR /bgold

RUN ./autogen.sh
RUN ./configure \
  --disable-shared \
  --disable-static \
  --disable-wallet \
  --disable-tests \
  --disable-bench \
  --enable-zmq \
  --with-utils \
  --without-libs \
  --without-gui
RUN make -j$(nproc)
RUN strip src/bgoldd src/bgold-cli


FROM alpine:3.8

RUN apk add --no-cache \
  boost \
  boost-program_options \
  openssl \
  libevent \
  zeromq

COPY --from=builder /bgold/src/bgoldd /bgold/src/bgold-cli /usr/local/bin/

RUN addgroup -g 1000 bgoldd \
  && adduser -u 1000 -G bgoldd -s /bin/sh -D bgoldd

USER bgoldd
RUN mkdir -p /home/bgoldd/.bgold

# P2P & RPC
EXPOSE 8338 8332

ENV \
  BGOLDD_DBCACHE=450 \
  BGOLDD_PAR=0 \
  BGOLDD_PORT=8338 \
  BGOLDD_RPC_PORT=8332 \
  BGOLDD_RPC_THREADS=4 \
  BGOLDD_ARGUMENTS=""

CMD exec bgoldd \
  -dbcache=$BGOLDD_DBCACHE \
  -par=$BGOLDD_PAR \
  -port=$BGOLDD_PORT \
  -rpcport=$BGOLDD_RPC_PORT \
  -rpcthreads=$BGOLDD_RPC_THREADS \
  $BGOLDD_ARGUMENTS
