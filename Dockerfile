FROM ubuntu:22.04

LABEL maintainer="mate.soos@ethereum.org"
LABEL version="0.1"
LABEL description="This is a custom Docker Image for symbolic execution benchmark running"

# RUN nix-env -iA nixpkgs.su
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl xz-utils sudo
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git bash

RUN adduser --system --group bench
RUN usermod -aG sudo bench
RUN echo "bench ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# RUN useradd -ms /bin/sh bench
RUN usermod --shell /bin/bash bench
USER bench
WORKDIR /home/bench

SHELL ["/bin/bash", "-c"]
ENV USER=bench
ENV HOME=/home/bench

RUN sudo install -d -m755 -o $(id -u) -g $(id -g) /nix
RUN curl -L https://nixos.org/nix/install | sh
RUN source $HOME/.nix-profile/etc/profile.d/nix.sh && nix-shell -p cachix --command "cachix use k-framework"

RUN git clone https://github.com/eth-sc-comp/benchmarks
WORKDIR /home/bench/benchmarks

RUN source $HOME/.nix-profile/etc/profile.d/nix.sh && nix --extra-experimental-features flakes --extra-experimental-features nix-command develop

RUN export HOME=/home/bench USER=bench
ENTRYPOINT ["/bin/bash", "-c", "source $HOME/.nix-profile/etc/profile.d/nix.sh && nix --extra-experimental-features flakes --extra-experimental-features nix-command develop"]
