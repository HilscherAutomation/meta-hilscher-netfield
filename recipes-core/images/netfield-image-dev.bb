require netfield-image.bb
############################################
# Development / Debugging / Testing Packages
############################################
IMAGE_INSTALL += "blktrace"
IMAGE_INSTALL += "ethtool tcpdump net-tools"
IMAGE_INSTALL += "iperf3 bonnie++ lmbench sysstat"
IMAGE_INSTALL += "procps psmisc powertop"
IMAGE_INSTALL += "bootchart systemd-analyze"
IMAGE_INSTALL += "strace iotop"
IMAGE_INSTALL += "htop bind-utils jq"
IMAGE_INSTALL += "python3-pip python3-virtualenv python3-simplejson"
IMAGE_INSTALL += "python3-psutil"
IMAGE_INSTALL += "subversion"

IMAGE_FEATURES += "tools-debug tools-profile"
