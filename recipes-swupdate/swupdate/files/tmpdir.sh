# Use tmpdir on backup or data partition to prevent out of memory conditions
tmpdir="/tmp/swupdate/tmp.unpack"
mkdir -p $tmpdir

for possible_loc in /mnt/backup /run/overlay; do
    free_space=$(df ${possible_loc} | grep "${possible_loc}$" | tr -s " " | cut -d " " -f 4)
    # Use location if more thatn 512 MB is free
    if [ $free_space -gt $((512 * 1024)) ]; then
        rm -rf $tmpdir
        mkdir -p ${possible_loc}/tmp.swupdate
        ln -sf ${possible_loc}/tmp.swupdate $tmpdir
        echo "Using ${possible_loc}/tmp.swupdate as temporary directory (Free Space: $free_space)"
        break
    fi
done

rm -rf $tmpdir/*

export TMPDIR="$tmpdir"
