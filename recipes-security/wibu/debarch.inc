def get_deb_arch(d):
    targetarch = d.getVar("TARGET_ARCH")

    if targetarch == "x86_64":
        return "amd64"
    elif targetarch == "arm":
        return "armhf"
    elif targetarch.startswith("aarch64"):
        return "arm64"
    else:
        bb.fatal(f"Unsupported targetarch {targetarch}")
