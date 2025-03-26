import os, sys, json

def check_log_entries(logfile=None, whitelist_logfile=None):
  with open(logfile) as fin:
    log_entries = fin.readlines()

  with open(whitelist_logfile,'r') as fin:
    whitelist_log_entries = fin.readlines()

  error_count = 0

  for log_entry in log_entries:
    log_obj = json.loads(log_entry)
    log_syslog_identifier = log_obj['SYSLOG_IDENTIFIER']
    log_message = log_obj['MESSAGE']

    is_expected_log_entry = 0

    for whitelist_log_entry in whitelist_log_entries:
      whitelist_log_obj = json.loads(whitelist_log_entry)
      whitelist_log_syslog_identifier = whitelist_log_obj['SYSLOG_IDENTIFIER']
      whitelist_log_message = whitelist_log_obj['MESSAGE']

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

print("Verify logfile %s against %s and check for new unexpected entries ..." % (dut_log_file, whitelist_log_file))
rc = check_log_entries(dut_log_file, whitelist_log_file)
if rc:
  print("... failed")
  exit(rc)
print("... done")

print("Verify logfile %s against %s and check for obsolete entries ... " % (whitelist_log_file, dut_log_file))
rc = check_log_entries(whitelist_log_file, dut_log_file)
if rc:
  print("... failed")
  exit(rc)
print("... done")

exit(0)
