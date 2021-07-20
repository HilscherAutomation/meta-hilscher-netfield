SRC_URI="git://bitbucket.hilscher.com/scm/ial/cockpit-netiot.git;user=${HILSCHER_BITBUCKET_USER};protocol=https;nobranch=1 \
         file://use_tarball_version_if_available.patch"
SRCREV = "6e8decfb742d586c7b24b708832a1e0dea53c541"

LIC_FILES_CHKSUM="file://COPYING;md5=4fbd65380cdd255951079008b364516c"

S="${WORKDIR}/git"

EXTRA_OECONF_append += "${@bb.utils.contains("IMAGE_FEATURES", "debug-tweaks", "--enable-debug", "" ,d)}"

do_configure_prepend() {
  export HOME="${WORKDIR}"

  username=$(echo ${HILSCHER_BITBUCKET_USER} | cut -d ":" -f1)
  password=$(echo ${HILSCHER_BITBUCKET_USER} | cut -d ":" -f2)
  echo "machine bitbucket.hilscher.com login $username password $password" > $HOME/.netrc

  git submodule init
  git submodule update --recursive

  npm install

  echo "${PV}" > ${S}/.tarball
}

require cockpit.inc
CVE_VERSION="194"
