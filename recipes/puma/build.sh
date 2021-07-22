#!/bin/bash
set -e  # exit when any command fails


echo "### INSTALLING pumapy ###"
cd "$SRC_DIR"
$PYTHON setup.py install --single-version-externally-managed --record=record.txt


echo "### INSTALLING PuMA C++ library ###"
cd install 
mkdir -p cmake-build-release
cd cmake-build-release
cmake -D CONDA_PREFIX=$PREFIX \
      -D CMAKE_INSTALL_PREFIX=$PREFIX \
      "$SRC_DIR"/cpp
make -j$CPU_COUNT
make install
rm ${PREFIX}/bin/pumaX_examples
rm ${PREFIX}/bin/pumaX_main


echo "### INSTALLING TexGen ###"
cd "$SRC_DIR"/install/TexGen
mkdir -p bin
cd bin
PY_VERSION="$(python -c 'import sys; print(sys.version_info[1])')"
if [ $PY_VERSION -le 7 ]; then
    PY_VERSION="${PY_VERSION}m"
fi
cmake -D BUILD_PYTHON_INTERFACE=ON \
      -D CMAKE_INSTALL_PREFIX=$PREFIX \
      -D PYTHON_INCLUDE_DIR="$PREFIX"/include/python3.$PY_VERSION \
      -D PYTHON_LIBRARY="$PREFIX"/lib/libpython3.$PY_VERSION$SHLIB_EXT \
      -D PYTHON_SITEPACKAGES_DIR="$SP_DIR" \
      -D BUILD_GUI=OFF \
      -D BUILD_RENDERER=OFF \
      -D CMAKE_MACOSX_RPATH=ON \
      -D CMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
      -D CMAKE_INSTALL_RPATH="$PREFIX"/lib \
      -D BUILD_SHARED_LIBS=OFF \
      ..
make -j$CPU_COUNT
make install


echo "### INSTALLING PuMA GUI ###"
cd "$SRC_DIR"/gui/build
if [ "$(uname)" != "Darwin" ]; then  # required for linux
      # openGL workaround
      echo "QMAKE_LIBS_OPENGL=${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64/libGL.so" >> pumaGUI.pro
        # missing g++ workaround.
      ln -s ${GXX} g++ || true
      chmod +x g++
      export PATH=${PWD}:${PATH}
fi
export CC=$(basename ${CC})
export CXX=$(basename ${CXX})
qmake \
      QMAKE_CC=${CC} \
      QMAKE_CXX=${CXX} \
      QMAKE_LINK=${CXX} \
      BUILD_PREFIX=$PREFIX \
      INSTALL_PREFIX=$PREFIX
make -j$CPU_COUNT
make install
