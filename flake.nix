{
  description = "Debian-based build and runtime environment for GreenALM using Nix Flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    shell-utils.url = "github:waltermoreira/shell-utils";
    intel-mpi.url = "github:Nixify-Technology/intel-mpi-nix";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , shell-utils
    , intel-mpi
    }:

    flake-utils.lib.eachDefaultSystem (system:
    let
      # Standard nix packages
      pkgs = import nixpkgs {
        inherit system;
      };

      config = nixpkgs.lib.trivial.importJSON ./config.json;
      shell = shell-utils.myShell.${system};
      intelmpi = intel-mpi.packages.${system}.default;

      tirpc = pkgs.stdenv.mkDerivation {
        name = "tirpc";
        buildInputs = [
          pkgs.cmake
          pkgs.autoconf
          pkgs.automake
          pkgs.libpkgconf
          pkgs.pkgconf
          pkgs.libtool
          pkgs.libtirpc
        ];
        src = pkgs.fetchzip
          {
            url = "https://github.com/couchbasedeps/libtirpc/archive/refs/heads/master.zip";
            hash = "sha256-6ozoxgqbUv+Os6o73XIy+UdJg8qyhRhtifRpBN2mi1M=";
          };
        buildPhase = ''
          echo "out = $out"

          mkdir -p $out/libtirpc
          autoreconf -i
          ./configure --prefix=$out/libtirpc
          make
          make install
          echo 'finish installing libtirpc'
        '';
        phases = [ "unpackPhase" "buildPhase" ];
      };

      app = pkgs.stdenv.mkDerivation {
        name = "must";
        buildInputs = [
          tirpc
          intelmpi
          pkgs.openssl
          pkgs.git
          pkgs.cmake
          pkgs.zsh
          pkgs.gfortran
          pkgs.ps
          pkgs.libxc
          pkgs.libtirpc
          pkgs.autoconf
          pkgs.automake
          pkgs.hdf5-fortran
          pkgs.libpkgconf
          pkgs.pkgconf
          pkgs.libtool
          pkgs.perl
          pkgs.wget
          pkgs.unzip
          pkgs.ntirpc
          pkgs.mkl
        ];
        nativeBuildInputs = with pkgs; [
        ];
        src = pkgs.fetchzip
          {
            url = "https://github.com/controny/MuST/archive/refs/tags/v1.1.0.zip";
            hash = "sha256-JdXt6AhnQf86BasVtbYmqA4iTOhd6Ht6b9dajDYqecA=";
          };
        buildPhase = ''
          BUILD_DIR=$(pwd)
          echo "BUILD_DIR = $BUILD_DIR"

          export XDR_INCLUDE=${tirpc}/libtirpc/include/tirpc/rpc
          echo "XDR_INCLUDE = $XDR_INCLUDE"
          export HOME=$BUILD_DIR
          export FCFLAGS="-fallow-argument-mismatch"

          cd $BUILD_DIR

          make ubuntu-gnu-nogpu \
            FFLAGS="-c -O3 -I. -fallow-argument-mismatch -lmkl_rt -lmkl_scalapack_lp64" \
            CPPDEFS=""
          make install

          mkdir -p $out/bin
          cp bin/* $out/bin

        '';
        phases = [ "unpackPhase" "buildPhase" ];
      };

    in
    {
      packages = {
        default = app;
      };
      devShells = {
        default = shell {
          name = "MuST";
          packages = [ tirpc app ];
        };
      };
    });

}
