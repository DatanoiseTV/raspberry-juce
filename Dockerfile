FROM debian:buster

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        automake \
        cmake \
        curl \
        fakeroot \
        g++ \
        git \
        make \
        runit \
        sudo \
        xz-utils \
        pkg-config \
        libasound2-dev \
        libfreetype6-dev \
        libcurl3-dev \
        libxinerama1 \
        libxinerama-dev

# Here is where we hardcode the toolchain decision.
ENV HOST=arm-linux-gnueabihf \
    TOOLCHAIN=arm-rpi-4.9.3-linux-gnueabihf \
    RPXC_ROOT=/rpxc

WORKDIR $RPXC_ROOT
RUN curl -L https://github.com/raspberrypi/tools/tarball/master \
  | tar --wildcards --strip-components 3 -xzf - "*/arm-bcm2708/$TOOLCHAIN/"

ENV ARCH=arm \
    CROSS_COMPILE=$RPXC_ROOT/bin/$HOST- \
    PATH=$RPXC_ROOT/bin:$PATH \
    QEMU_PATH=/usr/bin/qemu-arm-static \
    QEMU_EXECVE=1 \
    SYSROOT=$RPXC_ROOT/sysroot

WORKDIR $SYSROOT
RUN curl -Ls http://upload.vina-host.com/get/r8MTB/raspbian.2020.09.29.tar.xz \
    | tar -xJf - \
 && curl -Ls https://github.com/balena-io-library/armv7hf-debian-qemu/raw/master/bin/qemu-arm-static \
    > $SYSROOT/$QEMU_PATH \
 && chmod +x $SYSROOT/$QEMU_PATH \
 && mkdir -p $SYSROOT/build \
 && chroot $SYSROOT $QEMU_PATH /bin/sh -c '\
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
        && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
        && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                libc6-dev \
                symlinks \
        && symlinks -cors /'

RUN  chroot $SYSROOT $QEMU_PATH /bin/sh -c '\
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
        automake \
        cmake \
        curl \
        fakeroot \
        g++ \
        git \
        make \
        runit \
        sudo \
        xz-utils \
        pkg-config \
        libasound2-dev \
        libfreetype6-dev \
        libcurl3-dev \
        libxinerama1 \
        libxinerama-dev'

#RUN sudo ln -s /rpxc/local/lib/libwiringPi.so.2.36 /rpxc/lib/libwiringPi.so
#RUN sudo ln -s /rpxc/local/lib/libwiringPiDev.so.2.36 /rpxc/lib/libwiringPiDev.so

WORKDIR $SYSROOT

RUN git clone --depth=1 https://github.com/juce-framework/JUCE && \
    chroot $SYSROOT $QEMU_PATH /bin/sh -c 'cd JUCE && cmake . -B cmake-build -DJUCE_BUILD_EXAMPLES=ON -DJUCE_BUILD_EXTRAS=ON'
    
#ENTRYPOINT [ "/rpxc/entrypoint.sh" ]
