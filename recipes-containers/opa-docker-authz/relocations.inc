export sites=" \
    github.com/Microsoft/go-winio:github.com/Microsoft/go-winio \
    github.com/OneOfOne/xxhash:github.com/OneOfOne/xxhash \
    github.com/bytecodealliance/wasmtime-go:github.com/bytecodealliance/wasmtime-go \
    github.com/coreos/go-systemd:github.com/coreos/go-systemd \
    github.com/docker/go-connections:github.com/docker/go-connections \
    github.com/docker/go-plugins-helpers:github.com/docker/go-plugins-helpers \
    github.com/ghodss/yaml:github.com/ghodss/yaml \
    github.com/gobwas/glob:github.com/gobwas/glob \
    github.com/gorilla/mux:github.com/gorilla/mux \
    github.com/open-policy-agent/opa:github.com/open-policy-agent/opa \
    github.com/pkg/errors:github.com/pkg/errors \
    github.com/rcrowley/go-metrics:github.com/rcrowley/go-metrics \
    github.com/sirupsen/logrus:github.com/sirupsen/logrus \
    github.com/xeipuuv/gojsonpointer:github.com/xeipuuv/gojsonpointer \
    github.com/xeipuuv/gojsonreference:github.com/xeipuuv/gojsonreference \
    github.com/yashtewari/glob-intersection:github.com/yashtewari/glob-intersection \
    golang.org/x/net:golang.org/x/net \
    golang.org/x/sys:golang.org/x/sys \
    golang.org/x/text:golang.org/x/text \
    golang.org/x/time:golang.org/x/time \
    gopkg.in/yaml.v2:gopkg.in/yaml.v2 \
"

do_compile:prepend() {
    cd ${S}/src/import
    for s in $sites; do
        site_dest=$(echo $s | cut -d: -f1)
        site_source=$(echo $s | cut -d: -f2)
        force_flag=$(echo $s | cut -d: -f3)
        mkdir -p vendor.copy/$site_dest
        if [ -n "$force_flag" ]; then
            echo "[INFO] $site_dest: force copying .go files"
            rm -rf vendor.copy/$site_dest
            rsync -a --exclude='vendor/' --exclude='.git/' vendor.fetch/$site_source/ vendor.copy/$site_dest
        else
            [ -n "$(ls -A vendor.copy/$site_dest/*.go 2> /dev/null)" ] && { echo "[INFO] vendor.fetch/$site_source -> $site_dest: go copy skipped (files present)" ; true ; } || { echo "[INFO] $site_dest: copying .go files" ; rsync -a --exclude='vendor/' --exclude='.git/' vendor.fetch/$site_source/ vendor.copy/$site_dest ; }
        fi
    done
}
