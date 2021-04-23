#!/usr/bin/lua
--
-- This script provides preinst and postinst steps.
--

osReleaseFile = "/firmware.version"

osRescueBootMode = 1
osSingleBootMode = 2
osDualBootMode = 3

currBootMode = 0 -- unknown

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

function getBootMode()
	if os.execute("test -b /dev/disk/by-bootmode/active") == true then
		if os.execute("test -b /dev/disk/by-bootmode/standby-0") == true then
			return true, osDualBootMode
		else
			return true, osSingleBootMode
		end
	elseif os.execute("test -b /dev/disk/by-bootmode/rescue") == true then
		return true, osRescueMode
	else
		return false
	end
end

function mount_standby_system()
	os.execute("mkdir -p /media/system")
	if currBootMode == osRescueMode then
		swupdate.info("Rescue-Boot-Mode:\n")
		os.execute("mount -o nodelalloc /dev/disk/by-bootmode/standby-0 /media/system")
	elseif currBootMode == osSingleBootMode then
		swupdate.info("Single-Boot-Mode:\n")
		-- Check if system partition is read-only (default) If this fails directly mount it rw
		if os.execute("mount -o ro /dev/disk/by-bootmode/active /media/system") == true then
			os.execute("mount -o remount,rw,nodelalloc /media/system")
		else
			os.execute("mount -o nodelalloc /dev/disk/by-bootmode/active /media/system")
		end
	elseif currBootMode == osDualBootMode then
		swupdate.info("Dual-Boot-Mode:\n")
		os.execute("mount -o nodelalloc /dev/disk/by-bootmode/standby-0 /media/system")
	end

	return true
end

function umount_standby_system()
	os.execute("sync && umount /media/system && rmdir /media/system")
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

	swupdate.info("Valid firmware image found ("..newVersion.." > "..curVersion..").\n")
	return true
end

function pre_cleanup()
	if currBootMode == osDualBootMode or currBootMode == osRescueMode then
		os.execute("rm -rf /media/system/*boot.cfg*")
	elseif currBootMode == osSingleBootMode then
		if os.execute("grep -q bootCfg=.*/aboot.cfg /proc/cmdline") == true then
			os.execute("rm -rf /media/system/boot.cfg*")
		elseif os.execute("grep -q bootCfg=.*/boot.cfg /proc/cmdline") == true then
			os.execute("rm -rf /media/system/aboot.cfg*")
		end
	end

	-- Create a temporary dummy boot.cfg file to prevents possible warnings while deleting obsolete files.
	os.execute("touch /media/system/dummy-boot.cfg")

	-- Delete obsolete files
	os.execute("for file in $(find /media/system -maxdepth 1 -name *fitImage*); do grep -q $(basename $file) /media/system/*boot.cfg || rm $file*; done")
	os.execute("for file in $(find /media/system/ -maxdepth 1 -name *.rootfs.squashfs); do grep -q $(basename $file) /media/system/*boot.cfg || rm $file*; done")

	-- Delete the temporary created dummy boot.cfg file.
	os.execute("rm -f /media/system/dummy-boot.cfg")

	return true
end

function post_cleanup()
	if currBootMode == osDualBootMode then
		os.execute("mkdir -p /media/active")
		-- Check if system partition is read-only (default) If this fails directly mount it rw
		if os.execute("mount -o ro /dev/disk/by-bootmode/active /media/active") == true then
			os.execute("mount -o remount,rw,nodelalloc /media/active")
		else
			os.execute("mount /dev/disk/by-bootmode/active /media/active")
		end

		if os.execute("grep -q aboot.cfg /proc/cmdline") == true then
			swupdate.info("Keep the alternative boot configuration as we have booted in alternative mode!\n")
		else
			-- Mark active active boot configuration as alternative.
			os.execute("cp /media/active/boot.cfg /media/active/aboot.cfg")
			os.execute("cp /media/active/boot.cfg.sig /media/active/aboot.cfg.sig")
			os.execute("rm -f /media/active/boot.cfg*")
		end

		-- Activate new boot configuration on standby partition.
		os.execute("mv /media/system/nboot.cfg /media/system/boot.cfg")
		os.execute("mv /media/system/nboot.cfg.sig /media/system/boot.cfg.sig")

		-- Remove old alternative boot configuration from standby partition.
		os.execute("rm -f /media/system/aboot.cfg*")

		os.execute("sync && umount /media/active && rmdir /media/active")
	elseif currBootMode == osRescueMode or currBootMode == osSingleBootMode then
		if os.execute("grep -q aboot.cfg /proc/cmdline") == true then
			swupdate.info("Keep the alternative boot configuration as we have booted in alternative mode!\n")
		else
			-- Clone active boot configuration as alternative.
			os.execute("[ -f /media/system/boot.cfg ] && cp /media/system/boot.cfg /media/system/aboot.cfg")
			os.execute("[ -f /media/system/boot.cfg.sig ] && cp /media/system/boot.cfg.sig /media/system/aboot.cfg.sig")
		end

		-- Activate new boot configuration on standby partition.
		os.execute("mv /media/system/nboot.cfg /media/system/boot.cfg")
		os.execute("mv /media/system/nboot.cfg.sig /media/system/boot.cfg.sig")
	end

	return true
end

function rsync_boot()
	tmpdir = get_tmp_dir()

	if os.execute("test -f " .. tmpdir .. "/boot.squashfs") then
		-- First mount boot as read-only
		if os.execute("mkdir -p /media/boot && mount -o ro $(blkid -L boot) /media/boot") == true then
			os.execute("mkdir -p " .. tmpdir .. "/boot && mount " .. tmpdir .. "/boot.squashfs " .. tmpdir .. "/boot")
			if os.execute('which rsync > /dev/null') == true then
				-- Check if an update is required
				if os.execute('test -n "$(rsync -rcl --exclude nvd --delete -ni ' .. tmpdir .. '/boot/ /media/boot)"') == true then
					-- Remount for real update
					os.execute("mount -o remount,rw,nodelalloc /media/boot")
					-- Update the boot partition
					os.execute('rsync -rcl --exclude "nvd" --delete --inplace ' .. tmpdir .. '/boot/ /media/boot')
					swupdate.info("rsync update of boot partition done!\n")

					-- Verify files on target
					if os.execute('test -n "$(rsync -rcl --exclude nvd -ni ' ..tmpdir .. '/boot/ /media/boot)"') == true then
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
			os.execute("sync && umount /media/boot && rmdir /media/boot")
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
		rc = mount_standby_system()
		rc = pre_cleanup()

		os.execute("mkdir -p " .. tmpdir .. "/system && mount " .. tmpdir .. "/system.squashfs " .. tmpdir .. "/system")

		create_new_firmware_image_name_file()

		if os.execute('which rsync > /dev/null') == true then
			os.execute("rsync -rcl " ..tmpdir .. "/system/ /media/system")
			swupdate.info("rsync update of system partition done!\n")

			-- Verify files on target
			if os.execute('test -n "$(rsync -rcl -ni ' ..tmpdir .. '/system/ /media/system)"') == true then
				swupdate.info("Verification of system partition files failed!\n")
				return false
			end
			swupdate.info("System partition files successfully verified!\n")
		else
			os.execute("cp " .. tmpdir .. "/system/* /media/system/")
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
		os.execute('mkdir -p /media/system/oem')
		if os.execute('which rsync > /dev/null') == true then
			os.execute("mkdir -p " .. tmpdir .. "/data-oem && mount " .. oemfile .. " " .. tmpdir .. "/data-oem")
			-- Check if an update is required
			if os.execute('test -n "$(rsync -rcl --exclude nvd --delete -ni ' .. tmpdir .. '/data-oem/ /media/system/oem)"') == true then
				-- Update the oem data
				os.execute('rsync -rcl --exclude "nvd" --delete --inplace ' .. tmpdir .. '/data-oem/ /media/system/oem')
				swupdate.info("rsync update of oem data done!\n")

				-- Verify files on target
				if os.execute('test -n "$(rsync -rcl --exclude nvd -ni ' ..tmpdir .. '/data-oem/ /media/system/oem)"') == true then
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

	rc, currBootMode = getBootMode()
	if rc == false then
		swupdate.error("Invalid or missing partition scheme!\n")
		return false
	end

	-- Make sure temporary unpacking folder exists
	os.execute("mkdir -p /tmp/swupdate/tmp.unpack")

	-- Makes sure that /media is writable
	os.execute("touch /media/x 2>/dev/null && rm /media/x || mount -t tmpfs tmpfs /media")

	if os.execute("test ! -f /" .. tmpdir .. "/system.squashfs") then
		mount_standby_system()
		rc = pre_cleanup()
	end

	return true
end


function postinst()
	rc, currBootMode = getBootMode()
	if rc == false then
		swupdate.error("Invalid or missing partition scheme!\n")
		return false
	end

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

	umount_standby_system()

	rc = rsync_boot()
	if rc == false then
		return false
	end

	swupdate.info("Rebooting system ...\n")
	os.execute("(sleep 1; reboot;) &")

	return true
end
