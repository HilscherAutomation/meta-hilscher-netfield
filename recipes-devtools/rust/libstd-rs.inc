SUMMARY = "Rust standard libaries"
HOMEPAGE = "http://www.rust-lang.org"
SECTION = "devel"
LICENSE = "MIT | Apache-2.0"

RUSTLIB_DEP = ""
inherit cargo
# Make sure packages from crates.io are fetched
CARGO_DISABLE_BITBAKE_VENDORING = "1"

# Needed so cargo can find libbacktrace
RUSTFLAGS += "-L ${STAGING_LIBDIR} -C link-arg=-Wl,-soname,libstd.so"

SRC_URI += "https://static.rust-lang.org/dist/rustc-${PV}-src.tar.gz;name=rust"

# later versions of rust change the directory that they unextract to
RUSTSRC = "${WORKDIR}/rustc-${PV}-src"
S = "${RUSTSRC}/library/std"

# Don't use jemalloc as it doesn't work for many targets.
# https://github.com/rust-lang/rust/pull/37392
CARGO_FEATURES ?= "panic-unwind"

rustlibdir = "${libdir}/rust"

do_compile_prepend () {
    export CARGO_TARGET_DIR="${B}"
    # For Rust 1.13.0 and newer
    export RUSTC_BOOTSTRAP="1"
}

do_install () {
    mkdir -p ${D}${rustlibdir}

    # With the incremental build support added in 1.24, the libstd deps directory also includes dependency
    # files that get installed. Those are really only needed to incrementally rebuild the libstd library
    # itself and don't need to be installed.
    rm -f ${CARGO_RELEASE_DIR}/deps/*.d
    cp ${CARGO_RELEASE_DIR}/deps/* ${D}${rustlibdir}
}

FILES_${PN} += "${rustlibdir}/*.so"
FILES_${PN}-dev += "${rustlibdir}/*.rlib ${rustlibdir}/*.rmeta"
FILES_${PN}-dbg += "${rustlibdir}/.debug"
