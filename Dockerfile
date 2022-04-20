FROM ubuntu:focal

ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN    apt-get update                   \
    && apt-get upgrade --yes            \
    && apt-get install --yes            \
                        build-essential \
                        curl            \
                        git             \
                        python

# Install KEVM
ARG KEVM_VERSION=1.0.1
ARG KEVM_RELEASE=a8720c3
ENV KEVM_RELEASE_URL="https://github.com/runtimeverification/evm-semantics/releases/download/v${KEVM_VERSION}-${KEVM_RELEASE}/kevm_${KEVM_VERSION}_amd64_focal.deb"
RUN    curl -sSL ${KEVM_RELEASE_URL} --output /kevm.deb \
    && apt-get install --yes /kevm.deb                  \
    && rm -rf /kevm.deb

RUN groupadd user && useradd -m -s /bin/sh -g user user
USER user:user
WORKDIR /home/user

# Copy Benchmarks
ADD --chown=user:user benchmarks /home/user/benchmarks
