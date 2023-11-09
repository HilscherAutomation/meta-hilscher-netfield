PACKAGECONFIG ?= "openssl"

do_configure:append () {
	echo "CONFIG_EAP_FAST=y" >> wpa_supplicant/.config

    # Enable WPA3 support
    echo "CONFIG_SAE=y" >> wpa_supplicant/.config
    # OPENSSL_CMAC is needed, otherwise build fails with "undefined reference to 'omac1_aes_128'"
    # This is implicitely set by CONFIG_IEEE80211R (see https://lists.infradead.org/pipermail/hostap/2009-December/020723.html)
    echo "CONFIG_IEEE80211R=y" >> wpa_supplicant/.config
}
