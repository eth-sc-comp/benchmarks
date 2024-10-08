{
  description = "Eth SC Benchmarks";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";

    # tools
    hevm.url = "github:ethereum/hevm/bitwuzla-main";
    kontrol.url = "github:runtimeverification/kontrol";
    foundry.url = "github:shazow/foundry.nix/monthly";
    halmos-src = { url = "github:a16z/halmos"; flake = false; };
    runlim-src = { url = "github:msooseth/runlim"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, hevm, kontrol, foundry, halmos-src, runlim-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        runlim = pkgs.stdenv.mkDerivation {
          pname = "runlim";
          version = "1.0";
          configurePhase = ''
            mkdir -p $out/bin
            ./configure.sh --prefix=$out/bin
          '';
          src = runlim-src;
        };
        halmos = pkgs.python3.pkgs.buildPythonApplication rec {
          pname = "halmos";
          version = "0.0.0";
          src = halmos-src;
          format = "pyproject";
          doCheck = false;
          postPatch = ''
            # Use upstream z3 implementation
            sed -i '/^.*"z3-solver==.*",$/d' "pyproject.toml"
          '';
          buildInputs = with pkgs.python3.pkgs; [ setuptools ];
          propagatedBuildInputs = with pkgs.python3.pkgs; [ setuptools setuptools_scm z3 sortedcontainers toml ];
        };
      in rec {
        packages.default = halmos;
        devShells.default = pkgs.mkShell {
          DAPP_SOLC="${pkgs.solc}/bin/solc";
          packages = [
            # tools
            halmos
            hevm.packages.${system}.default
            kontrol.packages.${system}.default
            foundry.defaultPackage.${system}
            pkgs.solc

            # python stuff
            pkgs.black
            pkgs.ruff
            pkgs.python3

            # shell script deps
            pkgs.jq
            pkgs.sqlite-interactive
            pkgs.gnuplot
            pkgs.time
            runlim
          ];
        };
      });
}
