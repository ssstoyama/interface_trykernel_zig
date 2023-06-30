ARG zigv="zig-linux-aarch64-0.11.0-dev.3861+9343c31c3"

# Build
FROM debian:11-slim AS builder

ARG zigv

WORKDIR /tmp
RUN apt update && apt install -y \
  curl \
  xz-utils

RUN curl https://ziglang.org/builds/${zigv}.tar.xz \
  | tar -Jxvf -

# Package
FROM debian:11-slim

ARG zigv

RUN apt update && apt install -y \
      git \
      vim \
      make \
      g++ \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/${zigv} /usr/local/bin/${zigv}
RUN ln -s /usr/local/bin/${zigv}/zig /usr/local/bin/zig
