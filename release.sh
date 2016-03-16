#!/bin/sh

# Exit if anything fails
set -e

target=x86_64-elf
crossdir=$(pwd)"/cross"

# build it
mkdir build-gcc
cd build-gcc
../src/configure --prefix=$crossdir --target=$target --disable-nls --disable-werror --enable-languages=c,c++ --without-headers --enable-interwork --enable-multilib --with-gmp=/usr --with-mpc=/opt/local --with-mpfr=/opt/local
make
make install
cd ..

mkdir release
cd "$crossdir/bin"
strip *
tar czf "../../release/gcc-$HOST.tar.gz" *
cd ../..
