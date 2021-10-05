# Kernel Major.Minor specific path
FILESEXTRAPATHS_prepend := "${THISDIR}/linux-${@'.'.join(d.getVar('LINUX_VERSION', d).split('.')[:2])}:"

# Apply patches against fragattack from https://lore.kernel.org/linux-wireless/20210511180259.159598-1-johannes@sipsolutions.net/
FRAGATTACK_PATCHES = "file://fragattack/0001-mac80211-assure-all-fragments-are-encrypted.patch \
    file://fragattack/0002-mac80211-prevent-mixed-key-and-fragment-cache-attack.patch \
    file://fragattack/0003-mac80211-properly-handle-A-MSDUs-that-start-with-an-.patch \
    file://fragattack/0004-cfg80211-mitigate-A-MSDU-aggregation-attacks.patch \
    file://fragattack/0005-mac80211-drop-A-MSDUs-on-old-ciphers.patch \
    file://fragattack/0006-mac80211-add-fragment-cache-to-sta_info.patch \
    file://fragattack/0007-mac80211-check-defrag-PN-against-current-frame.patch \
    file://fragattack/0008-mac80211-prevent-attacks-on-TKIP-WEP-as-well.patch \
    file://fragattack/0009-mac80211-do-not-accept-forward-invalid-EAPOL-frames.patch \
    file://fragattack/0010-mac80211-extend-protection-against-mixed-key-and-fra.patch \
    file://fragattack/0011-ath10k-add-CCMP-PN-replay-protection-for-fragmented-.patch \
    file://fragattack/0012-ath10k-drop-fragments-with-multicast-DA-for-PCIe.patch \
    file://fragattack/0013-ath10k-drop-fragments-with-multicast-DA-for-SDIO.patch \
    file://fragattack/0014-ath10k-drop-MPDU-which-has-discard-flag-set-by-firmw.patch \
    file://fragattack/0015-ath10k-Fix-TKIP-Michael-MIC-verification-for-PCIe.patch \
    file://fragattack/0016-ath10k-Validate-first-subframe-of-A-MSDU-before-proc.patch \
"

FRAGATTACK_CVE_NUMBERS = "CVE-2020-24586 CVE-2020-24587 CVE-2020-24588 \
    CVE-2020-26139 CVE-2020-26140 CVE-2020-26141 CVE-2020-26142 CVE-2020-26143 \
    CVE-2020-26144 CVE-2020-26145 CVE-2020-26146 CVE-2020-26147"

SRC_URI_append += "${@oe.utils.version_less_or_equal('LINUX_VERSION', '5.4.123', '${FRAGATTACK_PATCHES}', '', d)}"
CVE_CHECK_WHITELIST_append += "${@oe.utils.version_less_or_equal('LINUX_VERSION', '5.4.123', '${FRAGATTACK_CVE_NUMBERS}', '', d)}"

