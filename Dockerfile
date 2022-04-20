FROM ubuntu:focal

ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN    apt-get update                    \
    && apt-get upgrade --yes             \
    && apt-get install --yes             \
                        build-essential  \
                        cmake            \
                        curl             \
                        git              \
                        libboost-all-dev \
                        pip              \
                        python

# Install solc
ARG SOLC_VERSION=0.8.11
RUN    git clone 'https://github.com/ethereum/solidity.git' --branch=v${SOLC_VERSION} \
    && cd solidity                                                                    \
    && mkdir -p build                                                                 \
    && cd build                                                                       \
    && cmake .. -DUSE_Z3=OFF -DUSE_CVC4=OFF                                           \
    && make -j8                                                                       \
    && make install                                                                   \
    && cd ../..                                                                       \
    && rm -rf solidity

# Install KEVM
ARG KEVM_VERSION=1.0.1
ARG KEVM_RELEASE=a8720c3
ENV KEVM_GITHUB_URL="https://github.com/runtimeverification/evm-semantics"
ENV KEVM_RELEASE_URL="${KEVM_GITHUB_URL}/releases/download/v${KEVM_VERSION}-${KEVM_RELEASE}/kevm_${KEVM_VERSION}_amd64_focal.deb"
RUN    curl -sSL "${KEVM_RELEASE_URL}" --output /kevm.deb \
    && apt-get install --yes /kevm.deb                    \
    && rm -rf /kevm.deb
RUN    git clone "${KEVM_GITHUB_URL}" --branch "v${KEVM_VERSION}-${KEVM_RELEASE}" evm-semantics-tmp \
    && pip install evm-semantics-tmp/kevm_pyk                                                       \
    && rm -rf evm-semantics-tmp

RUN groupadd user && useradd -m -s /bin/sh -g user user
USER user:user
WORKDIR /home/user

# Copy Benchmarks
ADD --chown=user:user benchmarks /home/user/benchmarks

# Copy Tool Scripts
ADD --chown=user:user tools /home/user/tools
