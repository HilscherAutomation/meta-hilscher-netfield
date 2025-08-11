export sites=" \
    github.com/elliotchance/orderedmap:github.com/elliotchance/orderedmap \
    github.com/fatih/color:github.com/fatih/color \
    github.com/goccy/go-yaml:github.com/goccy/go-yaml \
    github.com/jinzhu/copier:github.com/jinzhu/copier \
    github.com/spf13/cobra:github.com/spf13/cobra \
    github.com/timtadh/data-structures:github.com/timtadh/data-structures \
    github.com/timtadh/lexmachine:github.com/timtadh/lexmachine \
    golang.org/x/sys:golang.org/x/sys \
    gopkg.in/op/go-logging.v1:gopkg.in/op/go-logging.v1 \
    gopkg.in/yaml.v3:gopkg.in/yaml.v3 \
    github.com/mattn/go-colorable:github.com/mattn/go-colorable \
    github.com/mattn/go-isatty:github.com/mattn/go-isatty \
    github.com/spf13/pflag:github.com/spf13/pflag \
    golang.org/x/xerrors:golang.org/x/xerrors \
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
