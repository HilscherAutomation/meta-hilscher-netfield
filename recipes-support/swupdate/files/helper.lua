#!/usr/bin/lua
--
-- This script provides preinst and postinst steps.
--

osReleaseFile = "/firmware.version"

function get_tmp_dir()
	tmpdir = os.getenv("TMPDIR")
	if tmpdir == nil then
		tmpdir="/tmp"
	end
	return tmpdir
end

function string.starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

function split(inputstr, sep)
	if inputstr == nil then return {} end
	if sep == nil then sep = "%s" end

	t = {}; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end

	return t
end

function splitVersion(versionstr)
	t = split(versionstr, '.')

	for i=1,4,1 do
		if tonumber(t[i]) == nil then return end
	end
	version = string.format("%d.%d.%d.%d",t[1],t[2],t[3],t[4])

	type = t[5]
	if type == nil then type = "" end

	return version, type
end

function getCurVersion()
	f, err = io.open(osReleaseFile)
	if err then return nil, err end

	version = f:read()

	return version, err
end

function mount_system()
	os.execute("mkdir -p /mnt/system")

	-- NOTE:
	--   Retrieving the system partition device is done in a tricky way at this point,
	--   because the link /dev/disk/by-label/system might be wrong when netfieldOS is installed
	--   on eMMC and SD-Card (e.g. niot-e-nfl90-q2n16-n-rev1)!

	-- Check if system partition is read-only (default) If this fails directly mount it rw
	if os.execute("mount -o ro $(x=$(sed 's,.*bootCfg=\\(.*\\)/boot.cfg.*,\\1,' /proc/cmdline) && grep ^/dev <<< $x || blkid -o device -t $x) /mnt/system") == true then
		os.execute("mount -o remount,rw,nodelalloc /mnt/system")
	else
		os.execute("mount -o nodelalloc $(x=$(sed 's,.*bootCfg=\\(.*\\)/boot.cfg.*,\\1,' /proc/cmdline) && grep ^/dev <<< $x || blkid -o device -t $x) /mnt/system")
	end

	-- Due to a problem during production we may need to resize system partition
	os.execute("resize2fs $(x=$(sed 's,.*bootCfg=\\(.*\\)/boot.cfg.*,\\1,' /proc/cmdline) && grep ^/dev <<< $x || blkid -o device -t $x)")

	return true
end

function umount_system()
	os.execute("sync && umount /mnt/system && rmdir /mnt/system")
end

function check_version()
	local tmpdir = get_tmp_dir()
	local handle = io.popen("grep version " .. tmpdir .. "/sw-description | cut -d'\"' -f2")
	local newVersion = handle:read("*l")
	handle:close()

	curVersion, err = getCurVersion()
	curVersion, curType = splitVersion(curVersion)
	newVersion, newType = splitVersion(newVersion)

	if curVersion == nil then
		swupdate.error("Invalid or missing firmware version on installed system!\n")
		return false
	end
	if newVersion == nil then
		swupdate.error("Invalid or missing firmware version in new firmware image!\n")
		return false
	end

	if string.starts(curType, "debug") or string.starts(newType, "debug") then
		swupdate.info("You are on or installing a debug version: Skip firmware version verification ("..newVersion.."/"..curVersion..").")
		return true
	end

	if newVersion == curVersion then
		-- rc and beta have a version suffix (.rc-1 .beta-1)
		if string.starts(curType, "beta") then
			-- beta -> rc and release is allowed
			if string.starts(newType, "rc") or string.starts(newType, "release") then
				swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
				return true
			end

			-- beta-x -> beta-(x+y) is allowed
			if string.starts(newType, "beta") then
				cur_beta_idx = tonumber(split(curType, '-')[2])
				new_beta_idx = tonumber(split(newType, '-')[2])
				if new_beta_idx >= cur_beta_idx then
					swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
					return true
				end
			end

			swupdate.error("Denying upgrade/recovery current version:"..curVersion.."."..curType.." to be installed: "..newVersion.."."..newType.."!")
			return false
		end

		if string.starts(curType, "rc") then
			-- rc -> release is allowed
			if string.starts(newType, "release") then
				swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
				return true
			end

			-- rc-x -> rx-(x+y) is allowed
			if string.starts(newType, "rc") then
				cur_rc_idx = tonumber(split(curType, '-')[2])
				new_rc_idx = tonumber(split(newType, '-')[2])
				if new_rc_idx >= cur_rc_idx then
					swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
					return true
				end
			end

			swupdate.error("Denying upgrade/recovery current version:"..curVersion.."."..curType.." to be installed: "..newVersion.."."..newType.."!")
			return false
		end

		-- Allow factory default reset (same version and same type)
		if newType == curType then
			swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
			return true
		end

		swupdate.error("Invalid firmware version found ("..newVersion.." is already installed)!")
		return false
	end

	if newVersion < curVersion then
		swupdate.error("Invalid firmware version found ("..newVersion.." < "..curVersion..")!")
		return false
	end

	swupdate.info("Valid firmware image found ("..newVersion.." > "..curVersion..").\n")
	return true
end

function pre_cleanup()
	-- Delete the unbooted boot.cfg file to save disk space.
	os.execute("grep -q bootCfg=.*/aboot.cfg /proc/cmdline && rm -rf /mnt/system/boot.cfg*")
	os.execute("grep -q bootCfg=.*/boot.cfg /proc/cmdline && rm -rf /mnt/system/aboot.cfg*")

	-- Delete obsolete files
	os.execute("for file in $(find /mnt/system -maxdepth 1 -name *fitImage* -o -name *bzImage*); do grep -q $(basename $file) /mnt/system/*boot.cfg || rm $file*; done")
	os.execute("for file in $(find /mnt/system/ -maxdepth 1 -name *.rootfs.squashfs); do grep -q $(basename $file) /mnt/system/*boot.cfg || rm $file*; done")

	return true
end

function post_cleanup()
	if os.execute("grep -q aboot.cfg /proc/cmdline") == true then
		swupdate.info("Keep the alternative boot configuration as we have booted in alternative mode!\n")
	else
		-- Clone active boot configuration as alternative.
		os.execute("[ -f /mnt/system/boot.cfg ] && cp /mnt/system/boot.cfg /mnt/system/aboot.cfg")
		os.execute("[ -f /mnt/system/boot.cfg.sig ] && cp /mnt/system/boot.cfg.sig /mnt/system/aboot.cfg.sig")
	end

	-- Activate new boot configuration.
	os.execute("mv /mnt/system/nboot.cfg /mnt/system/boot.cfg")
	os.execute("mv /mnt/system/nboot.cfg.sig /mnt/system/boot.cfg.sig")

	return true
end

function rsync_boot()
	tmpdir = get_tmp_dir()

	if os.execute("test -f " .. tmpdir .. "/boot.squashfs") then
		-- First mount boot as read-only
		if os.execute("mkdir -p /mnt/boot && mount -o ro $(blkid -L boot) /mnt/boot") == true then
			os.execute("mkdir -p " .. tmpdir .. "/boot && mount " .. tmpdir .. "/boot.squashfs " .. tmpdir .. "/boot")
			if os.execute('which rsync > /dev/null') == true then
				-- Check if an update is required
				if os.execute('test -n "$(rsync -rcl --exclude nvd --delete -ni ' .. tmpdir .. '/boot/ /mnt/boot)"') == true then
					-- Remount for real update
					os.execute("mount -o remount,rw,nodelalloc /mnt/boot")
					-- Update the boot partition
					os.execute('rsync -rcl --exclude "nvd" --delete --inplace ' .. tmpdir .. '/boot/ /mnt/boot')
					swupdate.info("rsync update of boot partition done!\n")

					-- Verify files on target
					if os.execute('test -n "$(rsync -rcl --exclude nvd -ni ' ..tmpdir .. '/boot/ /mnt/boot)"') == true then
						swupdate.error("Verification of boot partition files failed!\n")
						return false
					end
					swupdate.info("Boot partition files successfully verified!\n")
				else
					swupdate.info("rsync update of boot partition skipped!\n")
				end
			else
				swupdate.info("rsync is missing, skipping boot partition update!\n")
			end
			os.execute("sync && umount " .. tmpdir .. "/boot && rmdir " .. tmpdir .. "/boot")
			os.execute("sync && umount /mnt/boot && rmdir /mnt/boot")
		end
		os.execute("rm " .. tmpdir .. "/boot.squashfs")
	end

	return true
end

function create_new_firmware_image_name_file()
	-- Used for suricatta (hawkbit) confirmations.
	if os.execute("test -e /etc/swupdate") then
		os.execute('grep "root=" ' .. tmpdir .. '/system/nboot.cfg | cut -d"\'" -f2 | sed "s,\\(.*[0-9]\\).*,\\1," > /etc/swupdate/firmware.image_name')
	end

	return true
end

function rsync_system()
	local tmpdir = get_tmp_dir()

	if os.execute("test -f " .. tmpdir .. "/system.squashfs") then
		rc = mount_system()
		rc = pre_cleanup()

		os.execute("mkdir -p " .. tmpdir .. "/system && mount " .. tmpdir .. "/system.squashfs " .. tmpdir .. "/system")

		create_new_firmware_image_name_file()

		if os.execute('which rsync > /dev/null') == true then
			os.execute("rsync -rcl " ..tmpdir .. "/system/ /mnt/system")
			swupdate.info("rsync update of system partition done!\n")

			-- Verify files on target
			if os.execute('test -n "$(rsync -rcl -ni ' ..tmpdir .. '/system/ /mnt/system)"') == true then
				swupdate.info("Verification of system partition files failed!\n")
				return false
			end
			swupdate.info("System partition files successfully verified!\n")
		else
			os.execute("cp " .. tmpdir .. "/system/* /mnt/system/")
			swupdate.info("manual update of system partition done!\n")
		end

		os.execute("sync && umount " .. tmpdir .. "/system && rmdir " .. tmpdir .. "/system")
		os.execute("rm " .. tmpdir .. "/system.squashfs")
	end

	return true
end

function rsync_data_oem()
	local tmpdir = get_tmp_dir()
	local handle = io.popen("ls -1 " .. tmpdir .. "/*data-oem.squashfs")
	local oemfile = handle:read("*l")
	local rc = {handle:close()}

	if rc[1] == true then
		swupdate.info("Updating / installing OEM image " .. oemfile .."\n")
		os.execute('mkdir -p /mnt/system/oem')
		if os.execute('which rsync > /dev/null') == true then
			os.execute("mkdir -p " .. tmpdir .. "/data-oem && mount " .. oemfile .. " " .. tmpdir .. "/data-oem")
			-- Check if an update is required
			if os.execute('test -n "$(rsync -rcl --exclude nvd --delete -ni ' .. tmpdir .. '/data-oem/ /mnt/system/oem)"') == true then
				-- Update the oem data
				os.execute('rsync -rcl --exclude "nvd" --delete --inplace ' .. tmpdir .. '/data-oem/ /mnt/system/oem')
				swupdate.info("rsync update of oem data done!\n")

				-- Verify files on target
				if os.execute('test -n "$(rsync -rcl --exclude nvd -ni ' ..tmpdir .. '/data-oem/ /mnt/system/oem)"') == true then
					swupdate.error("Verification of oem data files failed!\n")
					return false
				end
				swupdate.info("oem data files successfully verified!\n")
			else
				swupdate.info("rsync update of oem data skipped (already up to date)!\n")
			end
			os.execute("sync && umount " .. tmpdir .. "/data-oem && rmdir " .. tmpdir .. "/data-oem")
		else
			swupdate.info("rsync is missing, skipping oem data update!\n")
		os.execute("rm " .. oemfile)
		end
	end

	return true
end

function preinst()
	tmpdir = get_tmp_dir()

	rc = check_version()
	if rc == false then
		return false
	end

	if os.execute("test ! -f /" .. tmpdir .. "/system.squashfs") then
		mount_system()
		rc = pre_cleanup()
	end

	return true
end


function postinst()
	rc = rsync_system()
	if rc == false then
		return false
	end

	rc = post_cleanup()
	if rc == false then
		return false
	end

	rc = rsync_data_oem()
	if rc == false then
		return false
	end

	umount_system()

	rc = rsync_boot()
	if rc == false then
		return false
	end

	swupdate.info("Rebooting system ...\n")
	os.execute("(sleep 2; reboot;) &")

	return true
end
