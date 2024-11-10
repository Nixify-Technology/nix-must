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

      app = pkgs.stdenv.mkDerivation {
        name = "must";
        buildInputs = with pkgs; [
          openssl
          git
          openmpi
          mpich
          cmake
          zsh
          gfortran
          ps
          libxc
          libtirpc
          fftwMpi
          autoconf
          automake
          hdf5-fortran
          blas
          lapack
          libpkgconf
          pkgconf
          libtool
          perl
          wget
          unzip
          ntirpc
          scalapack
        ];
        nativeBuildInputs = with pkgs; [
        ];
        # src = /home/ubuntu/MuST;
        src = pkgs.fetchzip
          {
            url = "https://github.com/controny/MuST/archive/refs/heads/master.zip";
            hash = "sha256-CsdwU+BRNeVM3oABhk1u20Lre9tHG1kAXXdBtmpMj6M=";
          };
        buildPhase = ''
          # BUILD_DIR=$(pwd)
          # BUILD_DIR=/tmp/nix-fixed-build.drv/source
          BUILD_DIR=/tmp/nix-build-must.drv-3/source
          echo "BUILD_DIR = $BUILD_DIR"

          # install libtirpc
          wget https://github.com/couchbasedeps/libtirpc/archive/refs/heads/master.zip --no-check-certificate -O libtirpc.zip
          unzip libtirpc.zip
          cd libtirpc-master
          autoreconf -i
          mkdir -p $BUILD_DIR/libtirpc
          ./configure --prefix=$BUILD_DIR/libtirpc
          make
          make install
          echo 'finish installing libtirpc'

          export XDR_INCLUDE=$BUILD_DIR/libtirpc/include/tirpc/rpc
          export HOME=$BUILD_DIR

          cd $BUILD_DIR

          export FCFLAGS="-fallow-argument-mismatch"

          # make ubuntu-gnu-nogpu \
          #   FC="mpif90" \
          #   FPPDEFS="-cpp" \
          #   FFLAGS="-c -O3 -I. -fallow-argument-mismatch -lblas -llapack -lscalapack" \
          #   CC="mpicc" \
          #   ARCHV="ar -r" \
          #   LIBXC_PATH="$BUILD_DIR/external/libxc/LibXC/" \
          #   FFTW_PATH="$BUILD_DIR/external/fftw/FFTW/" \
          #   P3DFFT_PATH="$BUILD_DIR/external/p3dfft/P3DFFT/" \
          #   MKLPATH=""
          make ubuntu-gnu-nogpu \
            FFLAGS="-c -O3 -I. -fallow-argument-mismatch -lblas -llapack -lscalapack" \
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
          packages = [ app ];
        };
      };
    });

}
