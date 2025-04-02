import os, sys, json, re

def check_log_entries(logfile=None, whitelist_logfile=None):
  with open(logfile) as fin:
    log_entries = fin.readlines()

  with open(whitelist_logfile,'r') as fin:
    whitelist_log_entries = fin.readlines()

  error_count = 0

  for log_entry in log_entries:
    log_regex = False
    log_obj = json.loads(log_entry)
    if 'CONTAINER_ID' in log_obj:
      # NOTE: We're not interested in docker container logs, so let's skip them ...
      continue
    if 'optional' in log_obj:
      # NOTE: It is possible to define optional log entries in the whitelist logfile
      #       that are only used when comparing the runtime log entries against the whitelist log entries.
      print("INFO: Skipped log entry (%s)" % log_obj)
      continue
    if 'regex' in log_obj:
      log_regex = True
      log_obj = log_obj['regex']
    log_syslog_identifier = log_obj['SYSLOG_IDENTIFIER']
    log_message = log_obj['MESSAGE']

    if log_syslog_identifier == "journald-log-test":
      # NOTE: We're not interested in our own logs, so let's skip them ...
      continue

    is_expected_log_entry = 0

    for whitelist_log_entry in whitelist_log_entries:
      whitelist_log_optional = False
      whitelist_log_regex = False
      whitelist_log_obj = json.loads(whitelist_log_entry)
      if 'optional' in whitelist_log_obj:
        whitelist_log_optional = True
        whitelist_log_obj = whitelist_log_obj['optional']
      if 'regex' in whitelist_log_obj:
        whitelist_log_regex = True
        whitelist_log_obj = whitelist_log_obj['regex']
      whitelist_log_syslog_identifier = whitelist_log_obj['SYSLOG_IDENTIFIER']
      whitelist_log_message = whitelist_log_obj['MESSAGE']

      if log_regex is True or whitelist_log_regex is True:
        # NOTE: To test for outdated entries, check both directions,
        #       since the provided logfiles are swapped in such case
        #       and only the whitelist log file may contain regular expressions!
        if re.fullmatch(whitelist_log_syslog_identifier, log_syslog_identifier) == None and re.fullmatch(log_syslog_identifier, whitelist_log_syslog_identifier) == None:
          continue
        if re.fullmatch(whitelist_log_message, log_message) == None and re.fullmatch(log_message, whitelist_log_message) == None:
          continue
      else:
        if log_syslog_identifier != whitelist_log_syslog_identifier:
          continue
        if log_message != whitelist_log_message:
          continue

      is_expected_log_entry = 1
      break
    
    if is_expected_log_entry == 0:
      print("ERROR: Unexpected log entry (%s: %s)" % (log_syslog_identifier, log_message))
      error_count += 1
    
  return error_count

''' ======================================== '''

if len(sys.argv) < 2:
  print("Error: Invalid or missing argument (filename of whitelist logfile entries)")
  exit(1)

dut_log_file = 'dut.log'
whitelist_log_file = sys.argv[1]

os.system("journalctl -p warning -b --output json | jq '. | {'SYSLOG_IDENTIFIER': .SYSLOG_IDENTIFIER, 'MESSAGE': .MESSAGE, 'CONTAINER_ID': .CONTAINER_ID}' -c | sort | uniq > %s" % dut_log_file)
os.system("echo === DUT logfile created \(uptime: $(cat /proc/uptime | cut -d. -f1)\) === | systemd-cat -t journald-log-test -p warning")

print("Verify logfile %s against %s and check for new unexpected entries ..." % (dut_log_file, whitelist_log_file))
rc1 = check_log_entries(dut_log_file, whitelist_log_file)
if rc1:
  print("... failed")
else:
  print("... done")

print("Verify logfile %s against %s and check for obsolete entries ... " % (whitelist_log_file, dut_log_file))
rc2 = check_log_entries(whitelist_log_file, dut_log_file)
if rc2:
  print("... failed")
else:
  print("... done")

if (rc1 + rc2) != 0:
  os.system("cp %s ~/%s" % (dut_log_file, dut_log_file))
  os.system("cp %s ~/%s" % (whitelist_log_file, whitelist_log_file))

exit(rc1 + rc2)
