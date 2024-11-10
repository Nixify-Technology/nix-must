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
          FIXED_BUILD_DIR=/tmp/nix-fixed-build.drv
          cd $FIXED_BUILD_DIR

          echo current dir
          pwd

          # install librpc
          # wget https://github.com/johnandersen777/librpc/archive/refs/heads/master.zip --no-check-certificate
          # unzip master.zip
          # cd librpc-master
          # autoreconf -i
          # mkdir -p $FIXED_BUILD_DIR/librpc
          # ./configure --prefix=$FIXED_BUILD_DIR/librpc
          # make
          # make install
          # echo 'finish installing librpc'

          # install libtirpc
          # wget https://github.com/couchbasedeps/libtirpc/archive/refs/heads/master.zip --no-check-certificate -O libtirpc.zip
          # unzip libtirpc.zip
          # cd libtirpc-master
          # autoreconf -i
          # mkdir -p $FIXED_BUILD_DIR/libtirpc
          # ./configure --prefix=$FIXED_BUILD_DIR/libtirpc
          # make
          # make install
          # echo 'finish installing libtirpc'

          # export C_INCLUDE_PATH=$FIXED_BUILD_DIR/librpc/include:$FIXED_BUILD_DIR/libtirpc/include/tirpc:$C_INCLUDE_PATH
          # export LIBRARY_PATH=$FIXED_BUILD_DIR/librpc/lib:$FIXED_BUILD_DIR/libtirpc/lib:$LIBRARY_PATH
          # export LD_LIBRARY_PATH=$FIXED_BUILD_DIR/librpc/lib:$FIXED_BUILD_DIR/libtirpc/lib:$LD_LIBRARY_PATH
          # export PATH=$FIXED_BUILD_DIR/libtirpc/bin:$PATH

          export XDR_INCLUDE=$FIXED_BUILD_DIR/libtirpc/include/tirpc/rpc
          # export XDR_LIB=$FIXED_BUILD_DIR/libtirpc/lib

          cd $FIXED_BUILD_DIR/source

          # clear
          # cd MST/src
          # make clear
          # cd $FIXED_BUILD_DIR/source

          export HOME=$FIXED_BUILD_DIR

          make ubuntu-gnu-nogpu MST \
            FFLAGS="-c -O3 -I. -fallow-argument-mismatch -lblas -llapack" \
            LIBS="-lblas -llapack -lscalapack" \
            CFLAGS="-c -O3 -I$FIXED_BUILD_DIR/libtirpc/include/tirpc -L$FIXED_BUILD_DIR/libtirpc/lib -ltirpc -DNoXDR_format"
          
          make install

          touch $out

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
