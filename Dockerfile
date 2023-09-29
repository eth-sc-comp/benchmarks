FROM nixos/nix as builder

LABEL maintainer="mate.soos@ethereum.org"
LABEL version="0.1"
LABEL description="This is a custom Docker Image for symbolic execution benchmark running for MacOS"

RUN git clone https://github.com/eth-sc-comp/benchmarks
RUN cd benchmarks && nix --extra-experimental-features flakes --extra-experimental-features nix-command develop

ENTRYPOINT ["/bin/sh"]
