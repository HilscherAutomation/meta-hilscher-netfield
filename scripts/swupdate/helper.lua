#!/usr/bin/lua
--
-- This script provides preinst and postinst steps.
--

osReleaseFile = "/fw_version"

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

	return version,type
end

function getCurVersion()
	f,err = io.open(osReleaseFile)
	if err then return nil,err end

	version = f:read()

	return version,err
end

function file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

function mount_and_cleanup_system()
	os.execute("mkdir -p /mnt/system")

	-- NOTE:
	--   Retrieving the system partition device is done in a tricky way at this point,
	--   because the link /dev/disk/by-label/system might be wrong when netfieldOS is installed
	--   on eMMC and SD-Card (e.g. niot-e-nfl90-q2n16-n-rev1)!

	-- Check if system partition is read-only (default) If this fails directly mount it rw
	if os.execute("mount -o ro $(blkid -o device -t LABEL=system /dev/$(lsblk -no pkname $(grep -o 'bootCfg.*/boot.cfg' /proc/cmdline | cut -d= -f2 | cut -d/ -f1-3))*) /mnt/system") == true then
		os.execute("mount -o remount,rw,nodelalloc /mnt/system")
	else
		os.execute("mount -o nodelalloc $(blkid -o device -t LABEL=system /dev/$(lsblk -no pkname $(grep -o 'bootCfg.*/boot.cfg' /proc/cmdline | cut -d= -f2 | cut -d/ -f1-3))*) /mnt/system")
	end

	-- Due to a problem during production we may need to resize system partition
	os.execute("resize2fs $(blkid -o device -t LABEL=system /dev/$(lsblk -no pkname $(grep -o 'bootCfg.*/boot.cfg' /proc/cmdline | cut -d= -f2 | cut -d/ -f1-3))*)")

	-- Delete the unbooted boot.cfg file to make sure we have enough diskspace. We are recovering anyway cleaning everything.
	os.execute("grep -q bootCfg=.*/aboot.cfg /proc/cmdline && rm -rf /mnt/system/boot.cfg*")
	os.execute("grep -q bootCfg=.*/boot.cfg /proc/cmdline && rm -rf /mnt/system/aboot.cfg*")

	-- Delete obsolete files
	os.execute("for file in $(find /mnt/system -maxdepth 1 -name *fitImage*); do grep -q $(basename $file) /mnt/system/*boot.cfg || rm $file*; done")
	os.execute("for file in $(find /mnt/system/ -maxdepth 1 -name *.rootfs.squashfs); do grep -q $(basename $file) /mnt/system/*boot.cfg || rm $file*; done")
end

function preinst()
	newVersion = "@FW_VERSION@"

	curVersion,err = getCurVersion()
	curVersion,curType = splitVersion(curVersion)
	newVersion,newType = splitVersion(newVersion)

	if curVersion == nil then
		swupdate.error("Invalid or missing firmware version on installed system!")
		return false
	end
	if newVersion == nil then
		swupdate.error("Invalid or missing firmware version in new firmware image!")
		return false
	end

	if  string.starts(curType, "debug") or string.starts(newType, "debug") then
		mount_and_cleanup_system()
		swupdate.info("You are on or installing a debug version: Skip firmware version verification ("..newVersion.."/"..curVersion..")")
		return true
	end

	if newVersion == curVersion then
		-- rc and beta have a version suffix (.rc-1 .beta-1)
		if string.starts(curType, "beta") then
			-- beta -> rc and release is allowed
			if string.starts(newType, "rc") or string.starts(newType, "release") then
				mount_and_cleanup_system()
				swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
				return true
			end

			-- beta-x -> beta-(x+y) is allowed
			if string.starts(newType, "beta") then
				cur_beta_idx = tonumber(split(curType, '-')[2])
				new_beta_idx = tonumber(split(newType, '-')[2])
				if new_beta_idx >= cur_beta_idx then
					mount_and_cleanup_system()
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
				mount_and_cleanup_system()
				swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
				return true
			end

			-- rc-x -> rx-(x+y) is allowed
			if string.starts(newType, "rc") then
				cur_rc_idx = tonumber(split(curType, '-')[2])
				new_rc_idx = tonumber(split(newType, '-')[2])
				if new_rc_idx >= cur_rc_idx then
					mount_and_cleanup_system()
					swupdate.info("Upgrading/Recovering from "..curVersion.."."..curType.." to "..newVersion.."."..newType.."!")
					return true
				end
			end

			swupdate.error("Denying upgrade/recovery current version:"..curVersion.."."..curType.." to be installed: "..newVersion.."."..newType.."!")
			return false
		end

		-- Allow factory default reset (same version and same type)
		if newType == curType then
			mount_and_cleanup_system()
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

	mount_and_cleanup_system()

	swupdate.info("Valid firmware image found ("..newVersion.." > "..curVersion..").")
	return true
end

function postinst()
	os.execute("sync && umount /mnt/system && rmdir /mnt/system")

	swupdate.info("Rebooting system ...")
	os.execute("(sleep 1; reboot;) &")

	return true
end

