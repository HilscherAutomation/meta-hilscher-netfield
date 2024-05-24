export GOPROXY="https://proxy.golang.org,direct"

# GO_DYNLINK has problems with 1.21 available in yocto
# see https://github.com/yoctoproject/poky/commit/fd2e5e0b89d9c69acc9f813f07cd052630596ad5
GO_DYNLINK = ""
GO_DYNLINK:arm = ""
GO_DYNLINK:aarch64 = ""
GO_DYNLINK:x86 = ""
GO_DYNLINK:x86-64 = ""
GO_DYNLINK:powerpc64 = ""
GO_DYNLINK:powerpc64le = ""
GO_DYNLINK:class-native = ""
GO_DYNLINK:class-nativesdk = ""
