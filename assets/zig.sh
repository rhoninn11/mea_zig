#!/bin/bash

ZIG_VER="0.14.0"
install() {
    PKG="zig-linux-x86_64-${ZIG_VER}"
    mkdir -p /opt/zig && cd /opt/zig
    curl "https://ziglang.org/download/${ZIG_VER}/${PKG}.tar.xz" -o "${PKG}.tar.xz"
    tar -xf ${PKG}.tar.xz && mv $PKG zig-lang && rm ${PKG}.tar.xz
    export PATH="$PATH:/opt/zig/zig-lang" 

    git clone https://github.com/zigtools/zls.git \
    --depth 1 --branch ${ZIG_VER} /opt/zls
    cd /opt/zls && zig build -p /opt/zls

    echo 'export PATH="$PATH:/opt/zig/zig-lang"' > /etc/profile.d/zig.sh
    echo 'export PATH="$PATH:/opt/zls/bin"' >> /etc/profile.d/zig.sh
}