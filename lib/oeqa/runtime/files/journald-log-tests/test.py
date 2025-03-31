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
    if 'regex' in log_obj:
      log_regex = True
      log_obj = log_obj['regex']
    log_syslog_identifier = log_obj['SYSLOG_IDENTIFIER']
    log_message = log_obj['MESSAGE']

    is_expected_log_entry = 0

    for whitelist_log_entry in whitelist_log_entries:
      whitelist_log_regex = False
      whitelist_log_obj = json.loads(whitelist_log_entry)
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

os.system("journalctl -p warning -b --output json | jq '. | {'SYSLOG_IDENTIFIER': .SYSLOG_IDENTIFIER, 'MESSAGE': .MESSAGE}' -c | sort | uniq > %s" % dut_log_file)
os.system("echo '=== MARKER-1: DUT logfile created ===' | systemd-cat -t journald-log-test -p warning")

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

exit(rc1 + rc2)
