# Remove GPLv3 components
# NOTE: This may render pycparser unusable
RDEPENDS_${PN}_class-target_remove += "cpp cpp-symlinks"
