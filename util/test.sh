#!/bin/bash
#
# compiles and local installs the toolkit

# Alter where it will be installed (relative to the build directory)
INSTALLDIR=`pwd`/deploy
BUILDDIR=`pwd`/build

# Setup build and install directories (if needed)
mkdir -p $BUILDDIR $INSTALLDIR
cd $BUILDDIR
ln -fs ../../../../data cppsrc/libbiostreams/test/

# build
#cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Debug .. && make && ctest --verbose
cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Debug .. && make && ctest $*
