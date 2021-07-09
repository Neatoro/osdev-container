FROM alpine:3.14.0 as build

WORKDIR /tools

ARG binutilsversion=2.36
ARG gccversion=11.1.0

RUN apk add --no-cache curl
RUN curl -O https://ftp.gnu.org/gnu/binutils/binutils-${binutilsversion}.tar.gz
RUN curl -O https://ftp.gnu.org/gnu/gcc/gcc-${gccversion}/gcc-${gccversion}.tar.gz

RUN tar -xzf binutils-${binutilsversion}.tar.gz && rm binutils-${binutilsversion}.tar.gz
RUN tar -xzf gcc-${gccversion}.tar.gz && rm gcc-${gccversion}.tar.gz

RUN apk add --no-cache g++ make

ENV PREFIX="/tools/opt/cross"
ENV TARGET=i686-elf
ENV PATH="$PATH:$PREFIX/bin"

WORKDIR /tools/build-binutils
RUN ../binutils-${binutilsversion}/configure --target=$TARGET --prefix=$PREFIX --with-sysroot --disable-nls --disable-werror
RUN make
RUN make install

WORKDIR /tools/gcc-${gccversion}
RUN ./contrib/download_prerequisites

WORKDIR /tools/build-gcc
RUN ../gcc-${gccversion}/configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c --without-headers
RUN make all-gcc
RUN make all-target-libgcc
RUN make install-gcc
RUN make install-target-libgcc

FROM alpine:3.14.0

ENV PATH="$PATH:/tools/opt/cross/bin"

COPY --from=build /tools/opt/cross /tools/opt/cross
RUN apk add --no-cache grub

WORKDIR /project

CMD [ "ash" ]
