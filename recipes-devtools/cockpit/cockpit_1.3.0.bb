SRC_URI="git://bitbucket.hilscher.com/scm/ial/cockpit-netiot.git;user=${HILSCHER_BITBUCKET_USER};protocol=https;nobranch=1 \
         file://use_tarball_version_if_available.patch"
SRCREV = "306926ac328907f7e53a97e4103ca2285f01197b"

LIC_FILES_CHKSUM="file://COPYING;md5=4fbd65380cdd255951079008b364516c"

S="${WORKDIR}/git"

EXTRA_OECONF_append += "${@bb.utils.contains("IMAGE_FEATURES", "debug-tweaks", "--enable-debug", "" ,d)}"

do_configure_prepend() {
  export HOME="${WORKDIR}"

  username=$(echo ${HILSCHER_BITBUCKET_USER} | cut -d ":" -f1)
  password=$(echo ${HILSCHER_BITBUCKET_USER} | cut -d ":" -f2)
  password=$(python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus('$password'))")
  echo "machine bitbucket.hilscher.com login $username password $password" > $HOME/.netrc

  git submodule init
  git submodule update --recursive

  echo "${PV}" > ${S}/.tarball

  sh autogen.sh ${CONFIGUREOPTS} ${EXTRA_OECONF} $@
}

require cockpit.inc
CVE_VERSION="194"
