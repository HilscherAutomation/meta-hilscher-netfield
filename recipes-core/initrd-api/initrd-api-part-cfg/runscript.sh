#!/bin/sh

################################################################################
# Plugin Section
################################################################################

# Plugin: fat
do_mkfs_vfat() { mkfs.vfat $1 ${2:+-n $2} || return 1; }
do_fsck_vfat() { fsck.vfat -a $1 || return 1; }
do_fsresize_vfat() { return 1; } # currently unsupported

# Plugin: ext2
do_mkfs_ext2() { mkfs.ext2 -O 64bit -F $1 ${2:+-L $2} || return 1; }
do_fsck_ext2() { fsck.ext2 -y -f $1 || return 1; }
do_fsresize_ext2() { resize2fs $1 || return 1; }

# Plugin: ext3
do_mkfs_ext3() { mkfs.ext3 -O 64bit -F $1 ${2:+-L $2} || return 1; }
do_fsck_ext3() { fsck.ext3 -y -f $1 || return 1; }
do_fsresize_ext3() { resize2fs $1 || return 1; }

# Plugin: ext4
do_mkfs_ext4() { mkfs.ext4 -O 64bit -F $1 ${2:+-L $2} || return 1; }
do_fsck_ext4() { fsck.ext4 -y -f $1 || return 1; }
do_fsresize_ext4() { resize2fs $1 || return 1; }

# Plugin: btrfs
do_mkfs_btrfs() { mkfs.btrfs -f $1 ${2:+-L $2} || return 1; }
do_fsck_btrfs() { btrfsck --repair $1 || return 1; }
do_fsresize_btrfs() {
	local mp=$(mktemp -d) rc=0

	mkdir -p $mp
	mount $1 $mp
	btrfs filesystem resize max $mp || rc=1
	umount $1

	return $rc
}

# Plugin: extended
do_mkfs_extended() { return 0; }
do_fsck_extended() { return 0; }
do_fsresize_extended() { return 0; }

################################################################################
# Code Section
################################################################################

toBytes() {
  echo $1 | awk \
      'BEGIN{IGNORECASE = 1}
       function printpower(n,b,p) {printf "%u", n*b^p; next}
       /[0-9]$/{print $1;next};
       /K(iB)?$/{printpower($1,  2, 10)};
       /M(iB)?$/{printpower($1,  2, 20)};
       /G(iB)?$/{printpower($1,  2, 30)};
       /T(iB)?$/{printpower($1,  2, 40)};
       /KB$/{    printpower($1, 10,  3)};
       /MB$/{    printpower($1, 10,  6)};
       /GB$/{    printpower($1, 10,  9)};
       /TB$/{    printpower($1, 10, 12)}'
}

get_cur_dev_node() {
	local dev_node="${dev}${pn}"
	echo "$dev" | grep -q /dev/mmcblk && dev_node="${dev}p${pn}"
	echo $dev_node
}

get_free_part_info() {
	free_space=$(sfdisk -F ${dev} | head -n1 | cut -d ":" -f2 | cut -d "," -f2 | cut -d " " -f2)
	[ "${free_space}" = "0" ] && return 1
	free_part=$(sfdisk -F ${dev} | tail -n1 | tr -s " " | cut -d " " -f4)
}

create_part() {
	echo "Creating partition $pn ($conf_line) ..."

	# Read out information of free partition
	if ! get_free_part_info; then
		echo "Error: Creating partition ${pn} failed: Disk space empty!"
		return 1
	fi

	if [ "$part_tabel" = "dos" ]; then
		# Create new DOS partition
		case $fstype in
			'ext4' | 'ext3' | 'ext2' | 'btrfs') id="83" ;;
			'vfat') id="0c" ;;
			'lvm') id="8e" ;;
			'extended') id="05" ;;
			*) echo "Error: Invalid or missing partition type!"; return 1;;
		esac
	elif [ "$part_tabel" = "gpt" ]; then
		# Create new GPT partition
		case $fstype in
			'ext4' | 'ext3' | 'ext2' | 'btrfs') id="0FC63DAF-8483-4772-8E79-3D69D8477DE4" ;;
			'vfat') id="EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" ;;
			'lvm') id="E6D6D379-F507-44C2-A23C-238F2A3DF928" ;;
			*) echo "Error: Invalid or missing partition type!"; return 1;;
		esac
	else
		echo "Error: Invalid or missing partition table!"
		return 1
	fi

	[ "$size" = "max" ] && size=""
	start=$(sfdisk -F $dev | tail -n1 | cut -d ' ' -f1)
	part_spec="${start},${size},${id}"
	if ! flock $dev /bin/sh -c "echo $part_spec | sfdisk --no-reread -q -a $dev -W always"; then
		echo "Error: Creating partition ${pn} failed!"
		return 1
	fi

	# Format new partition with filesystem
	case "$fstype" in
		'ext4' | 'ext3' | 'ext2' | 'vfat' | 'btrfs')
			if ! do_mkfs_$fstype $dev_node $label; then
				echo "Error: Creating partition ${pn} ($dev_node, $fstype) failed: Filesystem error!"
				return 1
			fi
			;;
		'lvm')
			vgchange -an
			pvcreate $dev_node -ff -y -Zy
			vgcreate $vgname $dev_node -Zy
			vgchange -ay
			;;
		'extended')
			;;
		*)
			echo "Error: Creating partition ${pn} ($dev_node, $fstype) failed: Invalid or missing fstype!"
			echo "Error: Creating partition ${pn} ($dev_node, $fstype) failed: Supported fstype: ext4, ext3, ext2, vfat, btrfs!"
			return 1
			;;
	esac

	echo "Creating partition ${pn} ($dev_node, $fstype) successfully done!"

	return 0
}

resize_part() {
	echo "Resizing partition $pn ($conf_line) ..."

	# Read out information of free partition
	if ! get_free_part_info; then
		echo "Error: Creating partition ${pn} failed: Disk space empty!"
		return 1
	fi

	# Check size against shrinking
	cur_part_size_bytes=$(toBytes $cur_part_size)
	size_bytes=$(toBytes $size)
	if [ $size_bytes -lt $cur_part_size_bytes ]; then
		echo "Error: Resizing partition ${pn} failed: Size cannot shrink!"
		return 1
	fi

	# TODO: Check if partition fits on disk

	# Prepare the device for resizing.
	mp=$(grep $dev_node /proc/mounts | cut -d' ' -f2)
	[ -n "$mp" ] && umount $dev_node

	do_fsck_$fstype $dev_node

	# Resize partition
	[ "$size" = "max" ] && size="+"
	if ! flock $dev /bin/sh -c "echo ,${size} | sfdisk --no-reread -q -N ${pn} ${dev}"; then
		echo "Resizing partition ${pn} ($dev_node, $fstype) failed: Partition error!"
		return 1
	fi

	do_fsck_$fstype $dev_node

	# NOTE: We need to mount/unmount the device here to make sure mount time is set
	#       to something before last check time. Both informations are kept in the
	#       superblock of the filesystem. If last_checktime < last_mounttime resizing
	#       via resize2fs will fail with the need to run e2fsck.
	tmp_mp=$(mktemp -d)
	mount $dev_node $tmp_mp || {
		echo "Failed to mount ${dev_node}. Resizing will fail - aborting!"
		return 1
	}
	umount $dev_node
	rm -r $tmp_mp

	# Sometimes resize2fs complains about missing fsck (especially on intel virtual platforms)
	# so recheck filesystem
	do_fsck_$fstype $dev_node

	# Resize filesystem
	if ! do_fsresize_$fstype $dev_node; then
		echo "Resizing partition ${pn} ($dev_node, $fstype) failed: Filesystem error!"
		return 1
	fi

	# Cleanup
	[ -n "$mp" ] && mount $dev_node $mp

	echo "Resizing partition ${pn} ($dev_node, $fstype) successfully done!"

	return 0
}

create_logical_lvm_volume() {
	echo "Creating logical LVM volume $lvn ($conf_line) ..."

	if echo ${size} | grep -q "%"; then
		lvcreate -n $lvname -l ${size} $vgname -Zn
	else
		lvcreate -n $lvname -L ${size} $vgname -Zn
	fi

	vgchange -ay
	vgscan --mknodes

	# Format logical volume
	if ! yes | do_mkfs_$fstype /dev/mapper/$vgname-$lvname $label; then
		echo "Creating logical LVM volume ${lvn} (/dev/mapper/$vgname-$lvname, $fstype) failed!"
		return 1
	fi

	echo "Creating logical LVM volume ${lvn} (/dev/mapper/$vgname-$lvname, $fstype) successfully done!"
}

get_key_val() {
	echo $2 | sed 's/,/\n/g' | grep "^$1=" | cut -s -d'=' -f2
}

APP_NAME="Initial-Device-Partition-Manager"

do_main_exit() {
        exit_code=${1:-0}
        case $exit_code in
        0)
                echo "Exiting $APP_NAME successfully!"
                exit 0
                ;;
        *)
                echo "Exiting $APP_NAME erroneous ($exit_code)!"
                exit $exit_code
                ;;
        esac
}

do_main() {
	echo "Starting $APP_NAME ..."

	dev_list="$(cat part.cfg | grep ^device)"
	dev_list="$(echo $dev_list | cut -d "=" -f2)"

	for tmp_dev in $dev_list; do
		if [ -b "$tmp_dev" ]; then
			dev="$tmp_dev"
			break
		fi
	done

	if [ -z "$dev" ]; then
		echo "System device not found in $dev_list"
		do_main_exit 1
	else
		echo "Using system device $dev"
	fi

	# Unmount fs where apifile resides, as this usually resides on rescue partition
	api_mp=$(dirname $apifile)
	api_dev=$(cat /proc/mounts | grep $api_mp | cut -d " " -f1)
	umount $api_mp

	sgdisk=$(which sgdisk)
	[ -n "$sgdisk" ] && sgdisk -e $dev

	# Get a comma only separated partition configuration
	conf="$(cat part.cfg | tr -s ', ' ',')"
	cur_parts=$(sfdisk -o Device,Start,End,Sectors,Size,Type -lq ${dev} | sed "1 d" | tr -s " ")
	cur_parts_count=$(echo "$cur_parts" | wc -l)

	part_tabel="$(sfdisk -d ${dev} | grep label: | cut -d' ' -f2)"

	for conf_line in $conf; do
		part=$(get_key_val part $conf_line)
		[ -z "$part" ] && continue

		echo "========================================"

		size=$(get_key_val size $conf_line)
		fstype=$(get_key_val fstype $conf_line)
		label=$(get_key_val label $conf_line)
		vgname=$(get_key_val vgname $conf_line)

		[ "$part" == "lvm" -a -z "$fstype" ] && fstype="lvm" # <= Hack to prepare physical LVM volume
		if [ "$part" == "extended" ]; then
			[ "$part_tabel" != "dos" ] && { echo "Skip extended partitions for $part_tabel partition-tables."; continue; }
			[ -z "$fstype" ] && fstype="extended" # <= Hack to prepare extended partitions
		fi

		let pn++

		# Get device node of current partition
		dev_node=$(get_cur_dev_node)

		cur_part_conf=$(echo "$cur_parts" | head -n${pn} | tail -n1)

		# Check partition availability
		if [ ${cur_parts_count} -lt ${pn} ]; then
			create_part || do_main_exit 1
			continue
		fi

		# Check partition filesystem
		cur_part_fstype=$(lsblk -o NAME,FSTYPE ${dev_node} | sed "1 d" | head -n1 | tr -s " " | cut -d " " -f2 | sed "s/LVM2_member/lvm/")
		if [ "$cur_part_fstype" != "$fstype" ]; then
			echo "Error: Partition $dev_node: fstype mismatch ($fstype!=$cur_part_fstype)"
			do_main_exit 1
		fi

		# Check partition size
		cur_part_size=$(echo $cur_part_conf | cut -d " " -f5)
		if [ "$cur_part_size" != "$size" ]; then
			resize_part || do_main_exit 1
			continue
		fi

		echo "Partition $pn ($dev_node) okay!"
	done

	for conf_line in $conf; do
		lvname=$(get_key_val lvname $conf_line)
		[ -z "$lvname" ] && continue
		echo "========================================"

		let lvn++
		vgname=$(get_key_val vgname $conf_line)
		size=$(get_key_val size $conf_line)
		fstype=$(get_key_val fstype $conf_line)
		label=$(get_key_val label $conf_line)

		# Create logical LVM volume
		create_logical_lvm_volume || do_main_exit 1
	done

	echo "========================================"

	# Delete intrd-api file
	mount $api_dev $api_mp
	rm $apifile
	cp /tmp/initrdapi.log ${logfile:-/dev/null}
	sync

	do_main_exit 0
}

# Transform to comma only separated argument list
args=$(echo $* | tr ', ' ',')

apifile=$(get_key_val apifile $args)
logfile=$(get_key_val logfile $args)

do_main $@ 2>&1 | tee -a /tmp/initrdapi.log | sed 's/^/runscript.sh: /'

# Note: This code segment should never be reached!
exit $?
