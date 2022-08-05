# swupdate 2022.05 does not support path=/dev/null, which we are using for squashfs files.
# As we are allowing downgrades, we cannot update swupdate, without breaking downgrade support currently
# 2021.04 was the version being used in last images
PREFERRED_VERSION_swupdate = "2021.04"
